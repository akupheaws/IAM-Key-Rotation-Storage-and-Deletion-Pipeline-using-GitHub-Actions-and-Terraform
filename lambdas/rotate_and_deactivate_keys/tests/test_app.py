from lambdas.rotate_and_deactivate_keys.app import _env

def test_env_default(monkeypatch):
    monkeypatch.delenv("X_NOT_SET", raising=False)
    assert _env("X_NOT_SET", required=False, default="v") == "v"
