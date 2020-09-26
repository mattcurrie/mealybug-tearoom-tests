SRCDIR   = src
OBJDIR   = .o
DEPDIR   = .d
BINDIR   = build

SOURCES  := $(wildcard $(SRCDIR)/*.asm) $(wildcard $(SRCDIR)/*/*.asm)
OBJECTS  := $(SOURCES:$(SRCDIR)/%.asm=$(OBJDIR)/%.o)
DEPS  := $(SOURCES:$(SRCDIR)/%.asm=$(DEPDIR)/%.d)
ROMS  := $(SOURCES:$(SRCDIR)/%.asm=$(BINDIR)/%.gb)

all: $(ROMS)

$(ROMS): $(BINDIR)/%.gb : $(OBJDIR)/%.o
	@mkdir -p $(@D)
	rgblink -n $(basename $@).sym -m $(basename $@).map -o $@ $<
	rgbfix -v -p 255 $@

$(OBJECTS): $(OBJDIR)/%.o : $(SRCDIR)/%.asm
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
