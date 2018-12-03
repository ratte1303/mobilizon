import EctoEnum
defenum(AddressTypeEnum, :address_type, [:physical, :url, :phone, :other])

defmodule Mobilizon.Events.Event do
  @moduledoc """
  Represents an event
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Events.{Event, Participant, Tag, Category, Session, Track}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address

  schema "events" do
    field(:url, :string)
    field(:local, :boolean, default: true)
    field(:begins_on, Timex.Ecto.DateTimeWithTimezone)
    field(:description, :string)
    field(:ends_on, Timex.Ecto.DateTimeWithTimezone)
    field(:title, :string)
    # ???
    field(:state, :integer, default: 0)
    # Event status: TENTATIVE 1, CONFIRMED 2, CANCELLED 3
    field(:status, :integer, default: 0)
    # If the event is public or private
    field(:public, :boolean, default: true)
    field(:thumbnail, :string)
    field(:large_image, :string)
    field(:publish_at, Timex.Ecto.DateTimeWithTimezone)
    field(:uuid, Ecto.UUID, default: Ecto.UUID.generate())
    field(:address_type, AddressTypeEnum, default: :physical)
    field(:online_address, :string)
    field(:phone, :string)
    belongs_to(:organizer_actor, Actor, foreign_key: :organizer_actor_id)
    belongs_to(:attributed_to, Actor, foreign_key: :attributed_to_id)
    many_to_many(:tags, Tag, join_through: "events_tags")
    belongs_to(:category, Category)
    many_to_many(:participants, Actor, join_through: Participant)
    has_many(:tracks, Track)
    has_many(:sessions, Session)
    belongs_to(:physical_address, Address)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Event{} = event, attrs) do
    event
    |> Ecto.Changeset.cast(attrs, [
      :title,
      :description,
      :url,
      :begins_on,
      :ends_on,
      :organizer_actor_id,
      :category_id,
      :state,
      :status,
      :public,
      :thumbnail,
      :large_image,
      :publish_at,
      :address_type,
      :online_address,
      :phone
    ])
    |> cast_assoc(:tags)
    |> cast_assoc(:physical_address)
    |> build_url()
    |> validate_required([
      :title,
      :begins_on,
      :organizer_actor_id,
      :category_id,
      :url,
      :uuid,
      :address_type
    ])
  end

  @spec build_url(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp build_url(%Ecto.Changeset{changes: %{url: _url}} = changeset), do: changeset

  defp build_url(%Ecto.Changeset{changes: %{organizer_actor: organizer_actor}} = changeset) do
    organizer_actor
    |> Actor.actor_acct_from_actor()
    |> do_build_url(changeset)
  end

  defp build_url(%Ecto.Changeset{changes: %{organizer_actor_id: organizer_actor_id}} = changeset) do
    organizer_actor_id
    |> Mobilizon.Actors.get_actor!()
    |> Actor.actor_acct_from_actor()
    |> do_build_url(changeset)
  end

  defp build_url(%Ecto.Changeset{} = changeset), do: changeset

  @spec do_build_url(String.t(), Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp do_build_url(actor_acct, changeset) do
    uuid = Ecto.UUID.generate()

    changeset
    |> put_change(:uuid, uuid)
    |> put_change(:url, "#{MobilizonWeb.Endpoint.url()}/@#{actor_acct}/#{uuid}")
  end
end
