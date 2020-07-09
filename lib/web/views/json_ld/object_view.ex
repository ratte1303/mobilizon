defmodule Mobilizon.Web.JsonLD.ObjectView do
  use Mobilizon.Web, :view

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.Event
  alias Mobilizon.Posts.Post
  alias Mobilizon.Web.JsonLD.ObjectView
  alias Mobilizon.Web.MediaProxy

  def render("event.json", %{event: %Event{} = event}) do
    organizer = %{
      "@type" => if(event.organizer_actor.type == :Group, do: "Organization", else: "Person"),
      "name" => Actor.display_name(event.organizer_actor)
    }

    json_ld = %{
      "@context" => "https://schema.org",
      "@type" => "Event",
      "name" => event.title,
      "description" => event.description,
      # We assume for now performer == organizer
      "performer" => organizer,
      "organizer" => organizer,
      "location" => render_one(event.physical_address, ObjectView, "place.json", as: :address),
      "eventStatus" =>
        if(event.status == :cancelled,
          do: "https://schema.org/EventCancelled",
          else: "https://schema.org/EventScheduled"
        )
    }

    json_ld =
      if event.picture do
        Map.put(json_ld, "image", [
          event.picture.file.url |> MediaProxy.url()
        ])
      else
        json_ld
      end

    json_ld =
      if event.begins_on,
        do: Map.put(json_ld, "startDate", DateTime.to_iso8601(event.begins_on)),
        else: json_ld

    json_ld =
      if event.ends_on,
        do: Map.put(json_ld, "endDate", DateTime.to_iso8601(event.ends_on)),
        else: json_ld

    json_ld
  end

  def render("place.json", %{address: %Address{} = address}) do
    %{
      "@type" => "Place",
      "name" => address.description,
      "address" => %{
        "@type" => "PostalAddress",
        "streetAddress" => address.street,
        "addressLocality" => address.locality,
        "postalCode" => address.postal_code,
        "addressRegion" => address.region,
        "addressCountry" => address.country
      }
    }
  end

  def render("place.json", nil), do: %{}

  def render("post.json", %{post: %Post{} = post}) do
    %{
      "@context" => "https://schema.org",
      "@type" => "Article",
      "name" => post.title,
      "author" => %{
        "@type" => "Organization",
        "name" => Actor.display_name(post.attributed_to)
      },
      "datePublished" => post.publish_at,
      "dateModified" => post.updated_at
    }
  end
end
