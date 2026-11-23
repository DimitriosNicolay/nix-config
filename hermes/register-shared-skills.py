import os
from pathlib import Path
import sys
from tempfile import NamedTemporaryFile

from ruamel.yaml import YAML
from ruamel.yaml.error import YAMLError


def register_skill_directory(profile, directory, yaml):
    config = profile / "config.yaml"
    if config.is_symlink():
        raise ValueError("profile configuration is a symlink")
    settings = yaml.load(config) if config.exists() else {}
    if settings is None:
        settings = {}
    if not isinstance(settings, dict):
        raise ValueError("profile configuration must be a mapping")
    if settings.get("skills") is None:
        settings["skills"] = {}
    skills = settings["skills"]
    if not isinstance(skills, dict):
        raise ValueError("skills must be a mapping")
    external_dirs = skills.get("external_dirs")
    if external_dirs is None:
        external_dirs = []
    elif isinstance(external_dirs, str):
        external_dirs = [external_dirs]
    elif not isinstance(external_dirs, list):
        raise ValueError("skills.external_dirs must be a list or a path")

    if directory in external_dirs:
        return
    skills["external_dirs"] = [*external_dirs, directory]
    with NamedTemporaryFile(mode="w", encoding="utf-8", dir=profile, delete=False) as output:
        temporary_config = Path(output.name)
        try:
            yaml.dump(settings, output)
            output.flush()
            os.replace(temporary_config, config)
        finally:
            temporary_config.unlink(missing_ok=True)


hermes_home = Path(sys.argv[1])
hermes_home.mkdir(mode=0o700, exist_ok=True)
yaml = YAML()
for profile in [hermes_home, *(hermes_home / "profiles").glob("*")]:
    if profile.is_dir():
        try:
            register_skill_directory(profile, sys.argv[2], yaml)
        except (OSError, ValueError, YAMLError) as exc:
            print(f"Hermes: could not register shared skills for {profile} ({type(exc).__name__})", file=sys.stderr)
