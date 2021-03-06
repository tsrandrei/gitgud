defmodule GitGud.RepoTest do
  use GitGud.DataCase, async: true
  use GitGud.DataFactory

  alias GitGud.User
  alias GitGud.Repo
  alias GitGud.RepoStorage

  setup :create_user

  test "creates a new repository with valid params", %{user: user} do
    assert {:ok, repo} = Repo.create(factory(:repo, user))
    assert user.id in Enum.map(repo.maintainers, &(&1.id))
    assert File.dir?(RepoStorage.workdir(repo))
    File.rm_rf!(RepoStorage.workdir(repo))
  end

  test "fails to create a new repository with invalid name", %{user: user} do
    params = factory(:repo, user)
    assert {:error, changeset} = Repo.create(Map.delete(params, :name))
    assert "can't be blank" in errors_on(changeset).name
    assert {:error, changeset} = Repo.create(Map.update!(params, :name, &(&1<>"$")))
    assert "has invalid format" in errors_on(changeset).name
    assert {:error, changeset} = Repo.create(Map.update!(params, :name, &binary_part(&1, 0, 2)))
    assert "should be at least 3 character(s)" in errors_on(changeset).name
  end

  describe "when repository exists" do
    setup :create_repo

    test "fails to create a new repository with same name", %{user: user, repo: repo} do
      params = factory(:repo, user)
      assert {:error, changeset} = Repo.create(%{params|name: repo.name})
      assert "has already been taken" in errors_on(changeset).name
    end

    test "updates repository with valid params", %{repo: repo1} do
      assert {:ok, repo2} = Repo.update(repo1, name: "my-awesome-project", description: "This project is really awesome!")
      assert repo2.name == "my-awesome-project"
      assert repo2.description == "This project is really awesome!"
      File.rm_rf!(RepoStorage.workdir(repo2))
    end

    test "updates repository name moves Git workdir accordingly", %{repo: repo1} do
      assert {:ok, repo2} = Repo.update(repo1, name: "my-awesome-project")
      refute File.dir?(RepoStorage.workdir(repo1))
      assert File.dir?(RepoStorage.workdir(repo2))
      File.rm_rf!(RepoStorage.workdir(repo2))
    end

    test "fails to update repository with invalid name", %{repo: repo} do
      assert {:error, changeset} = Repo.update(repo, name: "")
      assert "can't be blank" in errors_on(changeset).name
      assert {:error, changeset} = Repo.update(repo, name: "my awesome project")
      assert "has invalid format" in errors_on(changeset).name
      assert {:error, changeset} = Repo.update(repo, name: "ap")
      assert "should be at least 3 character(s)" in errors_on(changeset).name
    end

    test "adds user to repository maintainers", %{user: user1, repo: repo1} do
      assert {:ok, user2} = User.create(factory(:user))
      assert {:ok, repo2} = Repo.update(repo1, maintainers: [user2|repo1.maintainers])
      assert user1.id in Enum.map(repo2.maintainers, &(&1.id))
      assert user2.id in Enum.map(repo2.maintainers, &(&1.id))
    end

    test "deletes repository", %{repo: repo1} do
      assert {:ok, repo2} = Repo.delete(repo1)
      assert repo2.__meta__.state == :deleted
    end
  end

  #
  # Helpers
  #

  defp create_user(context) do
    user = User.create!(factory(:user))
    on_exit fn ->
      File.rmdir(Path.join(Application.fetch_env!(:gitgud, :git_root), user.login))
    end
    Map.put(context, :user, user)
  end

  defp create_repo(context) do
    repo = Repo.create!(factory(:repo, context.user))
    on_exit fn ->
      File.rm_rf(RepoStorage.workdir(repo))
    end
    Map.put(context, :repo, repo)
  end
end
