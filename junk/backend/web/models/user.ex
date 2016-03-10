defmodule Backend.User do
  use Backend.Web, :model

  schema "users" do
    field :fullname, :string
    field :email, :string
    field :age, :integer

    timestamps
  end

  @required_fields ~w(fullname email age)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
