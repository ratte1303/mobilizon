defmodule MobilizonWeb.Schema.AddressType do
  @moduledoc """
  Schema representation for Address
  """
  use Absinthe.Schema.Notation
  alias MobilizonWeb.Resolvers

  object :address do
    field(:geom, :point, description: "The geocoordinates for the point where this address is")
    field(:floor, :string, description: "The floor this event is at")
    field(:street, :string, description: "The address's street name (with number)")
    field(:locality, :string, description: "The address's locality")
    field(:postal_code, :string)
    field(:region, :string)
    field(:country, :string)
    field(:description, :string)
  end

  object :phone_address do
    field(:phone, :string)
    field(:info, :string)
  end

  object :online_address do
    field(:url, :string)
    field(:info, :string)
  end

  object :address_queries do
    @desc "Search for an address"
    field :search_address, type: list_of(:address) do
      arg(:query, non_null(:string))

      resolve(&Resolvers.Address.search/3)
    end

    @desc "Reverse geocode coordinates"
    field :reverse_geocode, type: list_of(:address) do
      arg(:longitude, non_null(:float))
      arg(:latitude, non_null(:float))

      resolve(&Resolvers.Address.reverse_geocode/3)
    end
  end
end
