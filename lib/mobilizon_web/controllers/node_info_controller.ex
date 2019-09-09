# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/nodeinfo/nodeinfo_controller.ex

defmodule MobilizonWeb.NodeInfoController do
  use MobilizonWeb, :controller

  alias Mobilizon.CommonConfig
  alias Mobilizon.Service.Statistics

  @instance Application.get_env(:mobilizon, :instance)
  @node_info_supported_versions ["2.0", "2.1"]
  @node_info_schema_uri "http://nodeinfo.diaspora.software/ns/schema/"

  def schemas(conn, _params) do
    links =
      @node_info_supported_versions
      |> Enum.map(fn version ->
        %{
          rel: @node_info_schema_uri <> version,
          href:
            MobilizonWeb.Router.Helpers.node_info_url(MobilizonWeb.Endpoint, :nodeinfo, version)
        }
      end)

    json(conn, %{
      links: links
    })
  end

  # Schema definition: https://github.com/jhass/nodeinfo/blob/master/schemas/2.1/schema.json
  def nodeinfo(conn, %{"version" => version}) when version in @node_info_supported_versions do
    response = %{
      version: version,
      software: %{
        name: "Mobilizon",
        version: Keyword.get(@instance, :version)
      },
      protocols: ["activitypub"],
      services: %{
        inbound: [],
        outbound: ["atom1.0"]
      },
      openRegistrations: CommonConfig.registrations_open?(),
      usage: %{
        users: %{
          total: Statistics.get_cached_value(:local_users)
        },
        localPosts: Statistics.get_cached_value(:local_events),
        localComments: Statistics.get_cached_value(:local_comments)
      },
      metadata: %{
        nodeName: CommonConfig.instance_name(),
        nodeDescription: CommonConfig.instance_description()
      }
    }

    response =
      if version == "2.1" do
        put_in(response, [:software, :repository], Keyword.get(@instance, :repository))
      else
        response
      end

    conn
    |> put_resp_header(
      "content-type",
      "application/json; profile=http://nodeinfo.diaspora.software/ns/schema/2.1#; charset=utf-8"
    )
    |> json(response)
  end

  def nodeinfo(conn, _) do
    conn
    |> put_status(404)
    |> json(%{error: "Nodeinfo schema version not handled"})
  end
end
