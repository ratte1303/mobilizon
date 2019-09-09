defmodule MobilizonWeb.NodeInfoControllerTest do
  use MobilizonWeb.ConnCase

  @instance Application.get_env(:mobilizon, :instance)

  test "Get node info schemas", %{conn: conn} do
    conn = get(conn, node_info_path(conn, :schemas))

    assert json_response(conn, 200) == %{
             "links" => [
               %{
                 "href" =>
                   MobilizonWeb.Router.Helpers.node_info_url(
                     MobilizonWeb.Endpoint,
                     :nodeinfo,
                     "2.0"
                   ),
                 "rel" => "http://nodeinfo.diaspora.software/ns/schema/2.0"
               },
               %{
                 "href" =>
                   MobilizonWeb.Router.Helpers.node_info_url(
                     MobilizonWeb.Endpoint,
                     :nodeinfo,
                     "2.1"
                   ),
                 "rel" => "http://nodeinfo.diaspora.software/ns/schema/2.1"
               }
             ]
           }
  end

  test "Get node info", %{conn: conn} do
    # We clear the cache because it might have been initialized by other tests
    Cachex.clear(:statistics)
    conn = get(conn, node_info_path(conn, :nodeinfo, "2.1"))
    resp = json_response(conn, 200)

    assert resp == %{
             "metadata" => %{
               "nodeName" => Mobilizon.CommonConfig.instance_name(),
               "nodeDescription" => Mobilizon.CommonConfig.instance_description()
             },
             "openRegistrations" => Keyword.get(@instance, :registrations_open),
             "protocols" => ["activitypub"],
             "services" => %{"inbound" => [], "outbound" => ["atom1.0"]},
             "software" => %{
               "name" => "Mobilizon",
               "version" => Keyword.get(@instance, :version),
               "repository" => Keyword.get(@instance, :repository)
             },
             "usage" => %{"localComments" => 0, "localPosts" => 0, "users" => %{"total" => 0}},
             "version" => "2.1"
           }
  end

  test "Get node info with non supported version (1.0)", %{conn: conn} do
    conn = get(conn, node_info_path(conn, :nodeinfo, "1.0"))

    assert json_response(conn, 404) == %{"error" => "Nodeinfo schema version not handled"}
  end
end
