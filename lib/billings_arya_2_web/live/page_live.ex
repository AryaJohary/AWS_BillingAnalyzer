defmodule BillingsArya2Web.PageLive do
  use BillingsArya2Web, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Simulate the last 12 months of AWS billing data.
    months = [
      "Sep 2022", "Oct 2022", "Nov 2022", "Dec 2022",
      "Jan 2023", "Feb 2023", "Mar 2023", "Apr 2023",
      "May 2023", "Jun 2023", "Jul 2023", "Aug 2023"
    ]

    # Create a monthly cost trend using generated values.
    monthly_cost_trend =
      for month <- months do
        %{month: month, cost: (:rand.uniform() * 5000 |> Float.round(2))}
      end

    # Simulate a small daily cost trend.
    daily_cost_trend = [
      %{date: "2023-08-26", cost: 200.0},
      %{date: "2023-08-27", cost: 210.0},
      %{date: "2023-08-28", cost: 205.0}
    ]

    # Use the latest month's cost as the total monthly cost.
    total_monthly_cost = List.last(monthly_cost_trend).cost

    # Simulate cost breakdown by AWS services.
    cost_breakdown = %{
      "EC2"        => (:rand.uniform() * 2000 |> Float.round(2)),
      "S3"         => (:rand.uniform() * 1000 |> Float.round(2)),
      "RDS"        => (:rand.uniform() * 1500 |> Float.round(2)),
      "Lambda"     => (:rand.uniform() * 500  |> Float.round(2)),
      "CloudFront" => (:rand.uniform() * 800  |> Float.round(2))
    }

    # Derive cost comparison data from the first three months.
    cost_comparison = %{
      labels: Enum.map(Enum.take(monthly_cost_trend, 3), & &1.month),
      data: Enum.map(Enum.take(monthly_cost_trend, 3), & &1.cost)
    }

    # Simulate detailed billing records (as would come from AWS billing API).
    billing_records = [
      %{
        project_id: "Project-001",
        service_usage_details: "EC2 Instance Usage",
        product_code: "EC2-STD",
        line_item_description: "On-demand compute hours",
        cost: 123.45,
        usage_quantity: 100,
        period: "Aug 2023",
        payment_method: "Credit Card"
      },
      %{
        project_id: "Project-002",
        service_usage_details: "S3 Storage",
        product_code: "S3-STD",
        line_item_description: "Standard storage cost",
        cost: 67.89,
        usage_quantity: 250,
        period: "Aug 2023",
        payment_method: "Invoice"
      }
      # Add additional records as needed...
    ]

    # Removed "cost_threshold" from default filters.
    filters = %{"date_from" => nil, "date_to" => nil}

    socket =
      socket
      |> assign(:total_monthly_cost, total_monthly_cost)
      |> assign(:cost_breakdown, cost_breakdown)
      |> assign(:monthly_cost_trend, monthly_cost_trend)
      |> assign(:daily_cost_trend, daily_cost_trend)
      |> assign(:cost_comparison, cost_comparison)
      |> assign(:billing_records, billing_records)
      |> assign(:filters, filters)
      |> assign(:months, months)

    {:ok, socket}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filters_params}, socket) do
    # In a real app, you would apply these filters to your data query.
    socket = assign(socket, :filters, filters_params)
    {:noreply, socket}
  end

  @impl true
  def handle_event("download_report", _params, socket) do
    # Trigger your PDF report generation logic if needed.
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <!-- Dashboard Header -->
      <h1 class="text-2xl font-bold mb-4">Dashboard</h1>

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
end
