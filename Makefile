# Make does not offer a recursive wildcard function, so here's one:
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

SRC = src
BUILD = build
TEST = test-results

BUILD_CMD = ./node_modules/.bin/babel --presets es2015-node
TEST_CMD := node

SRC_FILES := $(call rwildcard,$(SRC)/,*.js) $(call rwildcard,$(SRC)/,*.json)
BUILD_FILES := $(patsubst %.json, %.js, $(patsubst $(SRC)/%, $(BUILD)/%, $(SRC_FILES)))
TEST_RESULT_FILES := $(patsubst $(SRC)/%.spec.js, $(TEST)/%.tap, $(SRC_FILES))

JSON_HEADER := 'module.exports ='

all: build unit-test

.PHONY: clean
test: clean-test unit-test

build: $(BUILD_FILES)
$(BUILD)/%.js: $(SRC)/%.js
	@echo Build: $< \> $@
	@mkdir -p $(@D)
	@$(BUILD_CMD) $< > $@
$(BUILD)/%.js: $(SRC)/%.json
	@echo Build: $< \> $@
	@mkdir -p $(@D)
	@echo $(JSON_HEADER) > $@ && cat $< >> $@

unit-test: $(TEST_RESULT_FILES)
$(TEST)/%.tap: $(BUILD)/%.spec.js $(BUILD)/%.js
	@printf "Test: $< > $@"
	@mkdir -p $(@D)
	@$(TEST_CMD) $< > $@ 2>> $@ && ([ $$? -eq 0 ] && printf " PASSED\n") || (printf " FAILED\n" && cat $@)
$(TEST)/%.tap: $(BUILD)/%.spec.js $(wildcard $(BUILD)/%/*.js) $(wildcard $(BUILD)/%/**/*.js)
	@printf "Test: $< > $@"
	@mkdir -p $(@D)
	@$(TEST_CMD) $< > $@ 2>> $@ && ([ $$? -eq 0 ] && printf " PASSED\n") || (printf " FAILED\n" && cat $@)

clean: clean-build clean-test
clean-build:
	rm -r $(BUILD)
clean-test:
	rm -r $(TEST)

watch:
	@echo Watching for changes...
	@fswatch $(SRC) | xargs -n1 -I{} make

