defmodule BillingsArya2Web.PageLive do
  use BillingsArya2Web, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Simulating the last 12 months of AWS billing data.
    months = [
      "Sep 2022", "Oct 2022", "Nov 2022", "Dec 2022",
      "Jan 2023", "Feb 2023", "Mar 2023", "Apr 2023",
      "May 2023", "Jun 2023", "Jul 2023", "Aug 2023"
    ]

    # monthly cost trend using generated values.
    monthly_cost_trend =
      for month <- months do
        %{month: month, cost: (:rand.uniform() * 5000 |> Float.round(2))}
      end

    # daily cost trend of 5 entries.
    daily_cost_trend =
      for i <- 0..4 do
        date = Date.utc_today() |> Date.add(-i) |> Date.to_string()
        cost = (:rand.uniform() * 50 + 150) |> Float.round(2)
        %{date: date, cost: cost}
      end

    # Using the latest month's cost as the total monthly cost.
    total_monthly_cost = List.last(monthly_cost_trend).cost

    # cost breakdown by AWS services.
    cost_breakdown = %{
      "EC2"        => (:rand.uniform() * 2000 |> Float.round(2)),
      "S3"         => (:rand.uniform() * 1000 |> Float.round(2)),
      "RDS"        => (:rand.uniform() * 1500 |> Float.round(2)),
      "Lambda"     => (:rand.uniform() * 500  |> Float.round(2)),
      "CloudFront" => (:rand.uniform() * 800  |> Float.round(2))
    }

    # Deriving cost comparison data from the first three months.
    cost_comparison = %{
      labels: Enum.map(Enum.take(monthly_cost_trend, 3), & &1.month),
      data: Enum.map(Enum.take(monthly_cost_trend, 3), & &1.cost)
    }

    # simulating detailed billing records (as would come from AWS billing API) with Period Start and Period End.
    billing_records = [
      %{
        project_id: "Project-001",
        service_usage_details: "EC2 Instance Usage",
        product_code: "EC2-STD",
        line_item_description: "On-demand compute hours",
        cost: 123.45,
        usage_quantity: 100,
        period_start: "2025-02-13",
        period_end: "2025-02-13",
        payment_method: "Credit Card"
      },
      %{
        project_id: "Project-002",
        service_usage_details: "S3 Storage",
        product_code: "S3-STD",
        line_item_description: "Standard storage cost",
        cost: 67.89,
        usage_quantity: 250,
        period_start: "2025-02-13",
        period_end: "2025-02-13",
        payment_method: "Invoice"
      },
      %{
        project_id: "Project-003",
        service_usage_details: "RDS Database",
        product_code: "RDS-STD",
        line_item_description: "Managed relational database service",
        cost: 210.00,
        usage_quantity: 50,
        period_start: "2025-02-13",
        period_end: "2025-02-13",
        payment_method: "Credit Card"
      },
      %{
        project_id: "Project-004",
        service_usage_details: "Lambda Functions",
        product_code: "LAMBDA-STD",
        line_item_description: "Compute usage for Lambda functions",
        cost: 89.99,
        usage_quantity: 300,
        period_start: "2025-02-13",
        period_end: "2025-02-13",
        payment_method: "Invoice"
      },
      %{
        project_id: "Project-005",
        service_usage_details: "CloudFront CDN",
        product_code: "CF-STD",
        line_item_description: "Content delivery network charges",
        cost: 150.75,
        usage_quantity: 80,
        period_start: "2025-02-13",
        period_end: "2025-02-13",
        payment_method: "Credit Card"
      }
    ]

    # Default filters.
    filters = %{"date_from" => nil, "date_to" => nil}
    filtered_billing_records = apply_filters(billing_records, filters)

    socket =
      socket
      |> assign(:total_monthly_cost, total_monthly_cost)
      |> assign(:cost_breakdown, cost_breakdown)
      |> assign(:monthly_cost_trend, monthly_cost_trend)
      |> assign(:daily_cost_trend, daily_cost_trend)
      |> assign(:cost_comparison, cost_comparison)
      |> assign(:billing_records, billing_records)
      |> assign(:filtered_billing_records, filtered_billing_records)
      |> assign(:filters, filters)
      |> assign(:months, months)

    {:ok, socket}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filters_params}, socket) do
    # date-based filters to the original billing records.
    filtered_billing_records = apply_filters(socket.assigns.billing_records, filters_params)
    socket =
      socket
      |> assign(:filters, filters_params)
      |> assign(:filtered_billing_records, filtered_billing_records)

    {:noreply, socket}
  end

  @impl true
  def handle_event("download_report", _params, socket) do
    # We will be handling it in client side hook in chart_hooks.js
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
    
      <h1 class="text-4xl font-bold mb-8">AWS Cost Analysis</h1>

      <!-- Metrics Overview -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <div class="bg-white shadow p-4 rounded">
          <h2 class="text-lg font-semibold">Total Monthly Cost</h2>
          <p class="text-2xl">$<%= @total_monthly_cost %></p>
        </div>
        <div class="bg-white shadow p-4 rounded">
          <h2 class="text-lg font-semibold">Cost Breakdown by Service</h2>
          <ul>
            <%= for {service, cost} <- @cost_breakdown do %>
              <li><%= service %>: $<%= cost %></li>
            <% end %>
          </ul>
        </div>
        <div class="bg-white shadow p-4 rounded">
          <h2 class="text-lg font-semibold">Cost Trends</h2>
          <p>View trends over time</p>
        </div>
      </div>

      <!-- Filters -->
      <div class="mb-8 bg-gray-100 p-4 rounded">
        <h2 class="text-xl font-semibold mb-2">Filters</h2>
        <.form :let={_f} for={@filters} phx-submit="update_filters">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label for="date_from" class="block">From:</label>
              <input
                type="date"
                id="date_from"
                name="filters[date_from]"
                value={@filters["date_from"] || ""}
                class="mt-1 block w-full"
              />
            </div>
            <div>
              <label for="date_to" class="block">To:</label>
              <input
                type="date"
                id="date_to"
                name="filters[date_to]"
                value={@filters["date_to"] || ""}
                class="mt-1 block w-full"
              />
            </div>
          </div>
          <div class="mt-4">
            <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded">
              Apply Filters
            </button>
          </div>
        </.form>
      </div>

      <!-- Detailed Billing Records (rendered as a table) -->
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
              <%= for record <- @filtered_billing_records do %>
                <tr>
                  <td class="px-4 py-2 whitespace-nowrap"><%= record.project_id %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= record.service_usage_details %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= record.product_code %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= record.line_item_description %></td>
                  <td class="px-4 py-2 whitespace-nowrap">$<%= record.cost %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= record.usage_quantity %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= record.period_start %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= record.period_end %></td>
                  <td class="px-4 py-2 whitespace-nowrap"><%= record.payment_method %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Data Visualization -->
      <div class="mb-8">
        <h2 class="text-xl font-semibold mb-4">Data Visualization</h2>
        <!-- Time-Series Charts -->
        <div class="mb-8">
          <h3 class="text-lg font-semibold mb-2">Time-Series Charts</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Monthly Cost Trend Chart -->
            <div class="bg-white shadow p-4 rounded">
              <h4 class="font-semibold mb-2">Monthly Cost Trend</h4>
              <div
                id="monthly-cost-chart"
                phx-hook="MonthlyCostChart"
                data-chart={Jason.encode!(@monthly_cost_trend)}
                class="h-64"
              ></div>
            </div>

            <!-- Daily Cost Trend Chart -->
            <div class="bg-white shadow p-4 rounded">
              <h4 class="font-semibold mb-2">Daily Cost Trend</h4>
              <div
                id="daily-cost-chart"
                phx-hook="DailyCostChart"
                data-chart={Jason.encode!(@daily_cost_trend)}
                class="h-64"
              ></div>
            </div>
          </div>
        </div>

        <!-- Bar Charts -->
        <div class="mb-8">
          <h3 class="text-lg font-semibold mb-2">Bar Charts</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Cost Breakdown by Service -->
            <div class="bg-white shadow p-4 rounded">
              <h4 class="font-semibold mb-2">Cost Breakdown by Service</h4>
              <div
                id="bar-chart-breakdown"
                phx-hook="BarChartBreakdown"
                data-chart={Jason.encode!(@cost_breakdown)}
                class="h-64"
              ></div>
            </div>

            <!-- Cost Comparison Chart -->
            <div class="bg-white shadow p-4 rounded">
              <h4 class="font-semibold mb-2">Cost Comparison</h4>
              <div
                id="bar-chart-comparison"
                phx-hook="BarChartComparison"
                data-chart={Jason.encode!(@cost_comparison)}
                class="h-64"
              ></div>
            </div>
          </div>
        </div>

        <!-- Pie Charts -->
        <div class="mb-8">
          <h3 class="text-lg font-semibold mb-2">Pie Charts</h3>
          <div class="bg-white shadow p-4 rounded">
            <h4 class="font-semibold mb-2">Cost Distribution by Service</h4>
            <div
              id="pie-chart-service"
              phx-hook="PieChartService"
              data-chart={Jason.encode!(@cost_breakdown)}
              class="h-64"
            ></div>
          </div>
        </div>
      </div>

      <!-- Detailed Reports -->
      <div class="mb-8">
        <h2 class="text-xl font-semibold mb-4">Detailed Reports</h2>
        <p>
          Download detailed reports in PDF format, including line item breakdowns,
          cost comparisons, and recommendations.
        </p>
        <button
          id="download-report-pdf"
          class="mt-2 bg-green-500 text-white px-4 py-2 rounded"
          phx-hook="DownloadPdf">
          Download Report PDF
        </button>
      </div>
    </div>
    """
  end

  # Date filtering logic copied from aws_test_live.ex and adapted to use our record keys.
  defp apply_filters(records, filters) do
    Enum.filter(records, fn record ->
      date_ok? =
        (case filters["date_from"] do
           "" -> true
           nil -> true
           from_date -> compare_date(record.period_start, from_date, :gte)
         end) and
        (case filters["date_to"] do
           "" -> true
           nil -> true
           to_date -> compare_date(record.period_end, to_date, :lte)
         end)

      date_ok?
    end)
  end

  defp compare_date(date_str, ref_date_str, :gte) do
    case {Date.from_iso8601(date_str), Date.from_iso8601(ref_date_str)} do
      {{:ok, date}, {:ok, ref_date}} ->
        Date.compare(date, ref_date) in [:gt, :eq]
      _ ->
        true
    end
  end

  defp compare_date(date_str, ref_date_str, :lte) do
    case {Date.from_iso8601(date_str), Date.from_iso8601(ref_date_str)} do
      {{:ok, date}, {:ok, ref_date}} ->
        Date.compare(date, ref_date) in [:lt, :eq]
      _ ->
        true
    end
  end
end
