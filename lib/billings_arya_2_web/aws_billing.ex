defmodule BillingsArya2Web.AWSBilling do
  # We need the following fields:
  #   • Project ID            -> from "bill/PayerAccountId"
  #   • Service Usage Details -> from "product/ProductName"
  #   • Product Code          -> from "lineItem/ProductCode"
  #   • Line-item Description -> from "lineItem/LineItemDescription"
  #   • Cost                  -> from "lineItem/UnblendedCost"
  #   • Usage Quantity        -> from "lineItem/UsageAmount"
  #   • Period Start          -> from "bill/BillingPeriodStartDate"
  #   • Period End            -> from "bill/BillingPeriodEndDate"
  #   • Payment Method        -> from "bill/BillType"
  require Logger

  #alias AWS.S3

  # Defining a CSV parser for CUR using NimbleCSV.
  NimbleCSV.define(MyParser, separator: ",", escape: "\"")

  @spec get_cur_report() :: {:ok, map()} | {:error, any()}
  def get_cur_report do
    # For CUR API calls, using "us-east-1" since that's the endpoint for CUR.
    client_cur = AWS.Client.create("us-east-1")
    # For S3 calls, using our bucket region.
    client_s3 = AWS.Client.create("us-east-1")

    case AWS.CostandUsageReport.describe_report_definitions(client_cur, %{}) do
      {:ok, %{"ReportDefinitions" => [report_def | _]}, _meta} ->
        bucket = report_def["S3Bucket"]

        # Listing objects
        with {:ok, list_response, _meta} <- AWS.S3.list_objects(client_s3, bucket) do
          latest_key = extract_csv_key(list_response)

          if latest_key do
            #Logger.info("Fetching CUR from bucket=#{bucket}, key=#{latest_key}")
            case AWS.S3.get_object(client_s3, bucket, latest_key) do
              {:ok, object, _meta} ->
                body = Map.get(object, "Body") || Map.get(object, :body)
                process_body(body)
              error ->
                #Logger.error("Error fetching CUR object: #{inspect(error)}")
                error
            end
          else
            {:error, "No CSV file found in bucket #{bucket}."}
          end
        else
          error ->
            error
        end

      {:ok, %{"ReportDefinitions" => []}, _meta} ->
        {:error, "No report definitions found in CUR"}
      error ->
        error
    end
  end

  # Processing the S3 object body: decompression if needed then parse the CSV,
  # then transform the parsed data into our desired schema, then aggregate cost data.
  defp process_body(body) do
    parsed_data = parse_cur_csv(body)

    # Logging the headers from the first parsed row.
    if parsed_data != [] do
      #Logger.info("Parsed headers: #{inspect(Map.keys(hd(parsed_data)))}")
    end

    # Logging only the top 2 parsed CSV rows.
    #Logger.info("Top 2 parsed CSV rows: #{inspect(Enum.take(parsed_data, 2))}")

    transformed = transform_data(parsed_data)
    aggregated = aggregate_cur_data(transformed)
    {:ok, %{line_items: transformed, aggregate: aggregated}}
  end

  # Extract the CSV key from the S3 list_objects response.
  defp extract_csv_key(response) do
    case response do
      %{"ListBucketResult" => %{"Contents" => contents}} ->
        contents = if is_list(contents), do: contents, else: [contents]
        contents
        |> Enum.filter(fn obj ->
          key = obj["Key"] || ""
          String.contains?(key, "AryaCostReport") and String.ends_with?(key, ".csv.gz")
        end)
        |> Enum.sort_by(& &1["LastModified"], &>=/2)
        |> List.first()
        |> case do
             nil -> nil
             obj -> obj["Key"]
           end

      %{"Contents" => contents} ->
        contents = if is_list(contents), do: contents, else: [contents]
        contents
        |> Enum.filter(fn obj ->
          key = obj["Key"] || ""
          String.contains?(key, "AryaCostReport") and String.ends_with?(key, ".csv.gz")
        end)
        |> Enum.sort_by(& &1["LastModified"], &>=/2)
        |> List.first()
        |> case do
             nil -> nil
             obj -> obj["Key"]
           end

      _ ->
        #Logger.warn("Unexpected S3 list_objects response: #{inspect(response)}")
        nil
    end
  end

  # Parses CSV content into a list of maps.
  # This version splits the content into lines using newline delimiters and uses the first line as headers.
  defp parse_cur_csv(csv_content) when is_binary(csv_content) do
    csv_text =
      try do
        :zlib.gunzip(csv_content)
      rescue
        _ -> csv_content
      end

    #Logger.debug("Raw CSV content: #{String.slice(csv_text, 0, 500)}")

    # Spliting the CSV text by newline (handling both \n and \r\n)
    lines =
      csv_text
      |> String.split(~r/\r?\n/, trim: true)

    case lines do
      [] ->
        []

      [header_line | data_lines] ->
        headers =
          header_line
          |> String.split(",")
          |> Enum.map(&String.trim/1)

        #Logger.info("Parsed headers: #{inspect(headers)}")

        Enum.map(data_lines, fn line ->
          values =
            line
            |> String.split(",")
            |> Enum.map(&String.trim/1)

          Enum.zip(headers, values)
          |> Enum.into(%{})
        end)
    end
  end

  defp transform_data(data) do
    Enum.map(data, fn item ->
      %{
        "Project ID"            => Map.get(item, "bill/PayerAccountId", "Unknown"),
        "Service Usage Details" => Map.get(item, "product/ProductName", "N/A"),
        "Product Code"          => Map.get(item, "lineItem/ProductCode", "N/A"),
        "Line-item Description" => Map.get(item, "lineItem/LineItemDescription", "N/A"),
        "Cost"                  => Map.get(item, "lineItem/UnblendedCost", "0"),
        "Usage Quantity"        => Map.get(item, "lineItem/UsageAmount", "0"),
        "Period Start"          => format_date(Map.get(item, "bill/BillingPeriodStartDate", "N/A")),
        "Period End"            => format_date(Map.get(item, "bill/BillingPeriodEndDate", "N/A")),
        "Payment Method"        => Map.get(item, "bill/BillType", "N/A")
      }
    end)
  end

  # Helper function to format the date string to "DD-MM-YYYY".
  defp format_date(date) when is_binary(date) do
    if String.length(date) >= 10 do
      date_to_format = String.slice(date, 0, 10)
      case Date.from_iso8601(date_to_format) do
        {:ok, parsed_date} ->
          Calendar.strftime(parsed_date, "%d-%m-%Y")
        _ ->
          date_to_format
      end
    else
      date
    end
  end

  # Aggregates cost data from the transformed line items.
  defp aggregate_cur_data(line_items) do
    total_cost =
      line_items
      |> Enum.reduce(0.0, fn item, acc ->
        cost =
          case Float.parse(item["Cost"]) do
            {num, _} -> num
            :error   -> 0.0
          end
        acc + cost
      end)

    project_totals =
      line_items
      |> Enum.group_by(fn item -> item["Project ID"] || "Unknown" end)
      |> Enum.map(fn {project, items} ->
        project_total =
          Enum.reduce(items, 0.0, fn item, acc ->
            cost =
              case Float.parse(item["Cost"]) do
                {num, _} -> num
                :error   -> 0.0
              end
            acc + cost
          end)
        {project, project_total}
      end)
      |> Enum.into(%{})

    %{
      total_cost: total_cost,
      project_totals: project_totals
    }
  end
end
