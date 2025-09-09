from pytest import raises
from lambdas.purge_deactivated_keys.app import _env

def test_env_missing(monkeypatch):
    monkeypatch.delenv("MISSING", raising=False)
    with raises(RuntimeError):
        _env("MISSING")
