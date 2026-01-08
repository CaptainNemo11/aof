SIM ?= questa

SUBDIRS := d1 d10

.PHONY: all $(SUBDIRS) clean

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ SIM=$(SIM)

clean:
	for d in $(SUBDIRS); do \
		$(MAKE) -C $$d clean; \
	done
