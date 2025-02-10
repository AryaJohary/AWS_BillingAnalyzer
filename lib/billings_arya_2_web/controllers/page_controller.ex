defmodule BillingsArya2Web.PageController do
  use BillingsArya2Web, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  # @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  # def index(conn, _params) do
  #   # Generate 5 random records and pass them to the view
  #   random_data = generate_random_data(5)
  #   render(conn, "index.html", random_data: random_data)
  # end

  # defp generate_random_data(count) do
  #   Enum.map(1..count, fn _ -> generate_random_record() end)
  # end

  # defp generate_random_record do
  #   %{
  #     project_id: "PRJ" <> Integer.to_string(:rand.uniform(1000)),
  #     service_usage_details:
  #       Enum.random(["Compute", "Storage", "Networking", "Database", "Monitoring"]),
  #     product_code: Enum.random(["PROD-A", "PROD-B", "PROD-C", "PROD-D"]),
  #     line_item_description:
  #       Enum.random(["Subscription fee", "Usage fee", "Service charge", "One-time fee"]),
  #     cost: (:rand.uniform() * 100) |> Float.round(2),
  #     usage_quantity: :rand.uniform(100),
  #     period: Enum.random(["2023-07", "2023-08", "2023-09"]),
  #     payment_method: Enum.random(["Credit Card", "Wire Transfer", "PayPal", "Bank Transfer"])
  #   }
  # end
end
