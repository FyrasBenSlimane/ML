"""Every sub-package here is a team member's model module.

The registry (app/core/registry.py) imports each package that does not start
with "_" and expects two names in its __init__.py:

    MODULE : ModuleInfo   — metadata shown in the app's Team hub
    router : APIRouter    — mounted at /api/v1/<MODULE.id>

Start from `_template/` — see INTEGRATION.md at the deployment root.
"""
