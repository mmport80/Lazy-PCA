defmodule Backend.User do
  use Backend.Web, :model

  schema "users" do
    field :fullname, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    has_many :plots2, Backend.Plot

    timestamps
  end

  @required_fields ~w(fullname username password) # password password_hash
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:username)
    |> validate_length(:username, min: 1, max: 20)
    |> validate_length(:fullname, min: 1, max: 20)
  end

  def registration_changeset(model, params) do
    model
    |> changeset(params)
    |> cast(params, ~w(password), [])
    |> validate_length(:password, min: 6, max: 100)
    |> put_pass_hash()

  end

  defp put_pass_hash(changeset) do
    case changeset do
        %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
            put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
        _ ->
            changeset
    end

  end

end
