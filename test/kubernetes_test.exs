defmodule Cluster.Strategy.KubernetesTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  alias Cluster.Strategy.Kubernetes
  alias Cluster.Nodes

  require Cluster.Nodes

  import ExUnit.CaptureLog

  setup do
    cassettes_path = Path.join([__DIR__, "fixtures", "vcr_cassettes"])
    ExVCR.Config.cassette_library_dir(cassettes_path, cassettes_path)
    ExVCR.Config.filter_request_headers("authorization")
    ExVCR.Config.filter_url_params(true)

    ExVCR.Config.filter_sensitive_data(
      "\"selfLink\":\"[^\"]+\"",
      "\"selfLink\":\"SELFLINK_PLACEHOLDER\""
    )

    ExVCR.Config.filter_sensitive_data("\"chart\":\"[^\"]+\"", "\"chart\":\"CHART_PLACEHOLDER\"")

    :ok
  end

  describe "start_link/1" do
    test "calls right functions" do
      use_cassette "kubernetes", custom: true do
        capture_log(fn ->
          start_supervised!({Kubernetes,
           [
             topology: :name,
             config: [
               kubernetes_node_basename: "test_basename",
               kubernetes_selector: "app=test_selector",
               # If you want to run the test freshly, you'll need to create a DNS Entry
               kubernetes_master: "cluster.localhost",
               kubernetes_service_account_path:
                 Path.join([__DIR__, "fixtures", "kubernetes", "service_account"])
             ],
             connect: {Nodes, :connect, [self()]},
             disconnect: {Nodes, :disconnect, [self()]},
             list_nodes: {Nodes, :list_nodes, [[]]},
             block_startup: true
           ]})

          assert_receive {:connect, _}, 5_000
        end)
      end
    end
  end
end
