SRCDIR   = src
OBJDIR   = build

SOURCES  := $(wildcard $(SRCDIR)/*.s)
OBJECTS  := $(SOURCES:$(SRCDIR)/%.s=$(OBJDIR)/%.o)
ROMS  := $(SOURCES:$(SRCDIR)/%.s=$(OBJDIR)/%.gb)

all: $(OBJDIR) $(ROMS) zip

$(OBJDIR):
	@echo "Creating $(directory)..."
	mkdir -p $@

$(ROMS): $(OBJDIR)/%.gb : $(OBJDIR)/%.o
	rgblink -n $(basename $@).sym -m $(basename $@).map -o $@ $<
	rgbfix -v -p 255 $@

$(OBJECTS): $(OBJDIR)/%.o : $(SRCDIR)/%.s
	rgbasm -o $@ $<

zip:
	rm mealybug-tearoom-tests.zip
	cd build && zip ../mealybug-tearoom-tests.zip *.gb

.PHONY: clean
clean:
	rm -rf $(OBJDIR)