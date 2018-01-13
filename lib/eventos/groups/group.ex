defmodule Eventos.Groups.Group.TitleSlug do
  alias Eventos.Groups.Group
  import Ecto.Query
  alias Eventos.Repo
  use EctoAutoslugField.Slug, from: :title, to: :slug

  def build_slug(sources, changeset) do
    slug = super(sources, changeset)
    build_unique_slug(slug, changeset)
  end

  defp build_unique_slug(slug, changeset) do
    query = from g in Group,
                 where: g.slug == ^slug

    case Repo.one(query) do
      nil -> slug
      _story ->
        slug
        |> increment_slug
        |> build_unique_slug(changeset)
    end
  end

  defp increment_slug(slug) do
    case List.pop_at(String.split(slug, "-"), -1) do
      {nil, _} ->
        slug
      {suffix, slug_parts} ->
        case Integer.parse(suffix) do
          {id, _} -> Enum.join(slug_parts, "-") <> "-" <> Integer.to_string(id + 1)
          :error -> slug <> "-1"
        end
    end
  end
end

defmodule Eventos.Groups.Group do
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Groups.{Group, Member, Request}
  alias Eventos.Accounts.Account
  alias Eventos.Groups.Group.TitleSlug

  schema "groups" do
    field :description, :string
    field :suspended, :boolean, default: false
    field :title, :string
    field :slug, TitleSlug.Type
    field :uri, :string
    field :url, :string
    many_to_many :accounts, Account, join_through: Member
    has_many :requests, Request

    timestamps()
  end

  @doc false
  def changeset(%Group{} = group, attrs) do
    group
    |> cast(attrs, [:title, :description, :suspended, :url, :uri])
    |> validate_required([:title, :description, :suspended, :url, :uri])
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()
  end
end