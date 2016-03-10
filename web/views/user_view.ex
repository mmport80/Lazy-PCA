defmodule Backend.UserView do
  use Backend.Web, :view

  def render("index.json", %{users: users}) do
    %{data: render_many(users, Backend.UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, Backend.UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{id: user.id,
      fullname: user.fullname,
      email: user.email,
      age: user.age}
  end
end
