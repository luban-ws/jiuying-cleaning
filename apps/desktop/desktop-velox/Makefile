.PHONY: bootstrap

bootstrap:
	@set -e; \
	echo "Preparing Velox dependencies..."; \
	swift package resolve >/dev/null 2>&1 || true; \
	VELOX_PATH=$${VELOX_PATH:-}; \
	if [ -z "$$VELOX_PATH" ]; then \
		if [ -d ".build/checkouts/velox/runtime-wry-ffi" ]; then VELOX_PATH=".build/checkouts/velox"; \
		elif [ -d "Packages/velox/runtime-wry-ffi" ]; then VELOX_PATH="Packages/velox"; \
		fi; \
	fi; \
	if [ -z "$$VELOX_PATH" ]; then \
		echo "Run swift package resolve first, or set VELOX_PATH"; exit 1; \
	fi; \
	chmod -R u+w "$$VELOX_PATH/runtime-wry-ffi" 2>/dev/null || true; \
	(cd "$$VELOX_PATH/runtime-wry-ffi" && cargo generate-lockfile && cargo fetch); \
	echo "Bootstrap complete"
