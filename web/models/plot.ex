defmodule Backend.Plot do
  use Backend.Web, :model

  schema "plots2" do
    #foreign key with user table
    #field :user_id, :integer
    field :source, :string
    field :ticker, :string
    field :frequency, :integer
    field :startDate, Ecto.Date
    field :endDate, Ecto.Date
    #match elm, can't be 'yield' in elm, reserved keyword
    field :y, :boolean
    field :deleted, :boolean
    #field :user_id, :integer

    belongs_to :user, Backend.User, foreign_key: :user_id

    timestamps
  end

  @required_fields ~w(source ticker frequency startDate endDate y deleted) # password password_hash
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:ticker, min: 1)
    |> foreign_key_constraint(:user_id)
  end

end
