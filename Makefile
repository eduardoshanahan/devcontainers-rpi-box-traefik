.DEFAULT_GOAL := help

.PHONY: help workspace

help:
	@echo "Available targets:"
	@echo "  workspace   Start or attach to the tmux workspace"

workspace:
	./workspace.sh

