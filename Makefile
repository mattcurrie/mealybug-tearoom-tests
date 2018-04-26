SRCDIR   = src
OBJDIR   = build

SOURCES  := $(wildcard $(SRCDIR)/*.s)
OBJECTS  := $(SOURCES:$(SRCDIR)/%.s=$(OBJDIR)/%.o)
ROMS  := $(SOURCES:$(SRCDIR)/%.s=$(OBJDIR)/%.gb)

all: $(OBJDIR) $(ROMS) 

$(OBJDIR):
	@echo "Creating $(directory)..."
	mkdir -p $@

$(ROMS): $(OBJDIR)/%.gb : $(OBJDIR)/%.o
	rgblink -n $(basename $@).sym -m $(basename $@).map -o $@ $<
	rgbfix -v -p 255 $@

$(OBJECTS): $(OBJDIR)/%.o : $(SRCDIR)/%.s
	rgbasm -o $@ $<

.PHONY: clean
clean:
	rm -rf $(OBJDIR)