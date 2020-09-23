SRCDIR   = src
OBJDIR   = .o
DEPDIR   = .d
BINDIR   = build

SOURCES  := $(wildcard $(SRCDIR)/*.s) $(wildcard $(SRCDIR)/*/*.s)
OBJECTS  := $(SOURCES:$(SRCDIR)/%.s=$(OBJDIR)/%.o)
DEPS  := $(SOURCES:$(SRCDIR)/%.s=$(DEPDIR)/%.d)
ROMS  := $(SOURCES:$(SRCDIR)/%.s=$(BINDIR)/%.gb)

all: $(ROMS)

$(ROMS): $(BINDIR)/%.gb : $(OBJDIR)/%.o
	@mkdir -p $(@D)
	rgblink -n $(basename $@).sym -m $(basename $@).map -o $@ $<
	rgbfix -v -p 255 $@

$(OBJECTS): $(OBJDIR)/%.o : $(SRCDIR)/%.s
	@mkdir -p $(@D)
	@mkdir -p $(@D:$(OBJDIR)/%=$(DEPDIR)/%)
	rgbasm -i mgblib/ -M $(DEPDIR)/$*.d -o $@ $<

$(DEPS):

include $(wildcard $(DEPS))

zip:
	rm mealybug-tearoom-tests.zip
	cd build && zip -r ../mealybug-tearoom-tests.zip . -i *.gb *.sym

.PHONY: clean
clean:
	rm -rf $(OBJDIR)
	rm -rf $(DEPDIR)
	rm -rf $(BINDIR)
