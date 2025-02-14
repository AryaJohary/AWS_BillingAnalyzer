defmodule BillingsArya2Web.AWSTestLive do
  use BillingsArya2Web, :live_view
  alias BillingsArya2Web.AWSBilling
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    case AWSBilling.get_cur_report() do
      {:ok, report_data} ->
        line_items = report_data.line_items
        aggregate = report_data.aggregate

        # Generating charts using the full (unfiltered) report data.
        monthly_cost_trend = generate_monthly_cost_trend(line_items)
        daily_cost_trend   = generate_daily_cost_trend(line_items)
        cost_breakdown     = generate_cost_breakdown(line_items)
        cost_comparison    = generate_cost_comparison(monthly_cost_trend)
        total_monthly_cost = get_total_monthly_cost(monthly_cost_trend)

        # Default filters and corresponding filtered line items.
        filters = %{"date_from" => "", "date_to" => ""}
        filtered_line_items = apply_filters(line_items, filters)

        socket =
          socket
          |> assign(:line_items, line_items)
          |> assign(:filtered_line_items, filtered_line_items)
          |> assign(:aggregate, aggregate)
          |> assign(:monthly_cost_trend, monthly_cost_trend)
          |> assign(:daily_cost_trend, daily_cost_trend)
          |> assign(:cost_breakdown, cost_breakdown)
          |> assign(:cost_comparison, cost_comparison)
          |> assign(:total_monthly_cost, total_monthly_cost)
          |> assign(:filters, filters)
          |> assign(:error, nil)

        {:ok, socket}

      {:error, error} ->
        Logger.error("CUR Error: #{inspect(error)}")
        socket =
          socket
          |> assign(:error, error)
          |> assign(:total_monthly_cost, 0.0)
          |> assign(:monthly_cost_trend, [])
          |> assign(:daily_cost_trend, [])
          |> assign(:cost_breakdown, %{})
          |> assign(:cost_comparison, %{})
          |> assign(:filtered_line_items, [])
          |> assign(:aggregate, nil)

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filters_params}, socket) do
    # Re-filter the original line items using the new filters.
    filtered_line_items = apply_filters(socket.assigns.line_items, filters_params)

    # Re-create all charts based on the filtered data.
    monthly_cost_trend = generate_monthly_cost_trend(filtered_line_items)
    daily_cost_trend   = generate_daily_cost_trend(filtered_line_items)
    cost_breakdown     = generate_cost_breakdown(filtered_line_items)
    cost_comparison    = generate_cost_comparison(monthly_cost_trend)
    total_monthly_cost = get_total_monthly_cost(monthly_cost_trend)

    socket =
      socket
      |> assign(:filters, filters_params)
      |> assign(:filtered_line_items, filtered_line_items)
      |> assign(:monthly_cost_trend, monthly_cost_trend)
      |> assign(:daily_cost_trend, daily_cost_trend)
      |> assign(:cost_breakdown, cost_breakdown)
      |> assign(:cost_comparison, cost_comparison)
      |> assign(:total_monthly_cost, total_monthly_cost)

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    default_filters = %{"date_from" => "", "date_to" => ""}
    filtered_line_items = apply_filters(socket.assigns.line_items, default_filters)

    monthly_cost_trend = generate_monthly_cost_trend(filtered_line_items)
    daily_cost_trend   = generate_daily_cost_trend(filtered_line_items)
    cost_breakdown     = generate_cost_breakdown(filtered_line_items)
    cost_comparison    = generate_cost_comparison(monthly_cost_trend)
    total_monthly_cost = get_total_monthly_cost(monthly_cost_trend)

    socket =
      socket
      |> assign(:filters, default_filters)
      |> assign(:filtered_line_items, filtered_line_items)
      |> assign(:monthly_cost_trend, monthly_cost_trend)
      |> assign(:daily_cost_trend, daily_cost_trend)
      |> assign(:cost_breakdown, cost_breakdown)
      |> assign(:cost_comparison, cost_comparison)
      |> assign(:total_monthly_cost, total_monthly_cost)

    {:noreply, socket}
  end

  @impl true
  def handle_event("download_report", _params, socket) do
    # The PDF download is handled via the client-side hook.
    {:noreply, socket}
  end

  # Helper to convert DD-MM-YYYY into ISO format (YYYY-MM-DD).
  defp normalize_date(date_str) when is_binary(date_str) do
    if Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, date_str) do
      date_str
    else
      case String.split(date_str, "-") do
        [day, month, year] -> "#{year}-#{month}-#{day}"
        _ -> date_str
      end
    end
  end

  # Helper to parse a cost value.
  defp parse_cost(cost) when is_binary(cost) do
    case Float.parse(cost) do
      {num, _} -> num
      :error   -> 0.0
    end
  end

  defp parse_cost(cost) when is_number(cost), do: cost

  # Group by month using the normalized "Period Start" field.
  defp generate_monthly_cost_trend(line_items) do
    line_items
    |> Enum.reduce(%{}, fn item, acc ->
      period_raw = item["Period Start"]
      period = normalize_date(period_raw)
      month =
        case period do
          <<year::binary-size(4), "-", mon::binary-size(2), _rest::binary>> ->
            "#{year}-#{mon}"
          _ -> "unknown"
        end

      cost = parse_cost(item["Cost"])
      Map.update(acc, month, cost, &(&1 + cost))
    end)
    |> Enum.map(fn {month, cost} -> %{month: month, cost: Float.round(cost, 2)} end)
    |> Enum.sort_by(& &1.month)
  end

  # Group by day using the normalized "Period Start" field.
  defp generate_daily_cost_trend(line_items) do
    line_items
    |> Enum.reduce(%{}, fn item, acc ->
      date_raw = item["Period Start"]
      date = normalize_date(date_raw)
      cost = parse_cost(item["Cost"])
      Map.update(acc, date, cost, &(&1 + cost))
    end)
    |> Enum.map(fn {date, cost} -> %{date: date, cost: Float.round(cost, 2)} end)
    |> Enum.sort_by(& &1.date)
  end

  # Aggregate cost breakdown by Service Usage Details.
  defp generate_cost_breakdown(line_items) do
    line_items
    |> Enum.reduce(%{}, fn item, acc ->
      key = item["Product Code"] || "Unknown"
      cost = parse_cost(item["Cost"])
      Map.update(acc, key, cost, &(&1 + cost))
    end)
    |> Enum.map(fn {k, cost} -> {k, Float.round(cost, 2)} end)
    |> Enum.into(%{})
  end

  # Build cost comparison data from the first three months.
  defp generate_cost_comparison(monthly_trend) do
    sorted_trend = Enum.sort_by(monthly_trend, & &1.month)
    first_three = Enum.take(sorted_trend, 3)
    %{
      labels: Enum.map(first_three, & &1.month),
      data: Enum.map(first_three, & &1.cost)
    }
  end

  # Retrieve the latest monthly cost.
  defp get_total_monthly_cost(monthly_trend) do
    if monthly_trend == [] do
      0.0
    else
      List.last(Enum.sort_by(monthly_trend, & &1.month)).cost
    end
  end

  # Date filtering logic with normalized dates.
  defp apply_filters(line_items, filters) do
    Enum.filter(line_items, fn item ->
      date_ok? =
        (case filters["date_from"] do
           "" -> true
           nil -> true
           from_date -> compare_date(item["Period Start"], from_date, :gte)
         end) and
        (case filters["date_to"] do
           "" -> true
           nil -> true
           to_date -> compare_date(item["Period End"], to_date, :lte)
         end)

      date_ok?
    end)
  end

  defp compare_date(date_str, ref_date_str, :gte) do
    normalized_date = normalize_date(date_str)
    case {Date.from_iso8601(normalized_date), Date.from_iso8601(ref_date_str)} do
      {{:ok, date}, {:ok, ref_date}} -> Date.compare(date, ref_date) in [:gt, :eq]
      _ -> true
    end
  end

  defp compare_date(date_str, ref_date_str, :lte) do
    normalized_date = normalize_date(date_str)
    case {Date.from_iso8601(normalized_date), Date.from_iso8601(ref_date_str)} do
      {{:ok, date}, {:ok, ref_date}} -> Date.compare(date, ref_date) in [:lt, :eq]
      _ -> true
    end
  end

  # Helpers for display in the table.
  defp display(val) when is_binary(val), do: if(String.trim(val) == "", do: "N/A", else: val)
  defp display(val), do: val
  defp display_number(val) when is_binary(val), do: if(String.trim(val) == "", do: "0", else: val)
  defp display_number(val), do: val

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <h1 class="text-4xl font-bold mb-8">AWS Cost Analysis</h1>

      <!-- Filters Section -->
      <div class="mb-8 bg-gray-100 p-4 rounded">
        <h2 class="text-xl font-semibold mb-2">Filters</h2>
        <.form :let={_f} for={@filters} phx-submit="update_filters">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label for="date_from" class="block">From:</label>
              <input type="date" id="date_from" name="filters[date_from]"
                value={@filters["date_from"] || ""} class="mt-1 block w-full" />
            </div>
            <div>
              <label for="date_to" class="block">To:</label>
              <input type="date" id="date_to" name="filters[date_to]"
                value={@filters["date_to"] || ""} class="mt-1 block w-full" />
            </div>
          </div>
          <div class="mt-4 flex space-x-2">
            <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded">
              Apply Filters
            </button>
            <button type="button" phx-click="clear_filters" class="bg-gray-500 text-white px-4 py-2 rounded">
              Clear Filters
            </button>
          </div>
        </.form>
      </div>

      <!-- Detailed Billing Records Table -->
      <div class="mb-8">
        <h2 class="text-xl font-semibold mb-2">Detailed Billing Records</h2>
        <div class="bg-white shadow rounded max-h-96 overflow-y-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50 sticky top-0 z-10">
              <tr>
                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Project ID</th>
                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Service Usage Details</th>
                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Product Code</th>
                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Line-item Description</th>
                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Cost</th>
                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Usage Quantity</th>
                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Period Start</th>
                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Period End</th>
                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Payment Method</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for item <- @filtered_line_items do %>
                <tr>
                  <td class="px-4 py-2 whitespace-nowrap"><%= display(item["Project ID"]) %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= display(item["Service Usage Details"]) %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= display(item["Product Code"]) %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= display(item["Line-item Description"]) %></td>
                  <td class="px-4 py-2 whitespace-nowrap">$<%= display_number(item["Cost"]) %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= display(item["Usage Quantity"]) %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= display(item["Period Start"]) %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= display(item["Period End"]) %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= display(item["Payment Method"]) %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Data Visualization Section (Charts Based on Filtered Data) -->
      <div class="mb-8">
        <h2 class="text-xl font-semibold mb-4">Data Visualization</h2>
        <!-- Time-Series Charts -->
        <div class="mb-8">
          <h3 class="text-lg font-semibold mb-2">Time-Series Charts</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Monthly Cost Trend Chart -->
            <div class="bg-white shadow p-4 rounded">
              <h4 class="font-semibold mb-2">Monthly Cost Trend</h4>
              <div id="monthly-cost-chart" phx-hook="MonthlyCostChart" data-chart={Jason.encode!(@monthly_cost_trend)} class="h-64"></div>
            </div>
            <!-- Daily Cost Trend Chart -->
            <div class="bg-white shadow p-4 rounded">
              <h4 class="font-semibold mb-2">Daily Cost Trend</h4>
              <div id="daily-cost-chart" phx-hook="DailyCostChart" data-chart={Jason.encode!(@daily_cost_trend)} class="h-64"></div>
            </div>
          </div>
        </div>
        <!-- Bar Charts -->
        <div class="mb-8">
          <h3 class="text-lg font-semibold mb-2">Bar Charts</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Cost Breakdown by Service Bar Chart -->
            <div class="bg-white shadow p-4 rounded">
              <h4 class="font-semibold mb-2">Cost Breakdown by Service</h4>
              <div id="bar-chart-breakdown" phx-hook="BarChartBreakdown" data-chart={Jason.encode!(@cost_breakdown)} class="h-64"></div>
            </div>
            <!-- Cost Comparison Chart -->
            <div class="bg-white shadow p-4 rounded">
              <h4 class="font-semibold mb-2">Cost Comparison</h4>
              <div id="bar-chart-comparison" phx-hook="BarChartComparison" data-chart={Jason.encode!(@cost_comparison)} class="h-64"></div>
            </div>
          </div>
        </div>
        <!-- Pie Charts -->
        <div class="mb-8">
          <h3 class="text-lg font-semibold mb-2">Pie Charts</h3>
          <div class="bg-white shadow p-4 rounded">
            <h4 class="font-semibold mb-2">Cost Distribution by Service</h4>
            <div id="pie-chart-service" phx-hook="PieChartService" data-chart={Jason.encode!(@cost_breakdown)} class="h-64"></div>
          </div>
        </div>
      </div>

      <!-- Detailed Reports Section -->
      <div class="mb-8">
        <h2 class="text-xl font-semibold mb-4">Detailed Reports</h2>
        <p>
          Download detailed reports in PDF format, including line item breakdowns,
          cost comparisons, and recommendations.
        </p>
        <button id="download-report-pdf" class="mt-2 bg-green-500 text-white px-4 py-2 rounded" phx-hook="DownloadPdf">
          Download Report PDF
        </button>
      </div>
    </div>
    """
  end
end
