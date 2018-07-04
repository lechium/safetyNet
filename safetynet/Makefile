CC = $(shell xcrun -l -f clang)
SYSROOT = $(shell xcrun -l --sdk appletvos --show-sdk-path)

INCLUDES = -I. -ISCEvents -I$(SYSROOT)/usr/include
CFLAGS = $(INCLUDES) -fobjc-arc -arch arm64 -isysroot $(SYSROOT)
LDFLAGS = -framework Foundation -framework MobileCoreServices

BOBJ ?= build/obj

BUILD_FLD = build/usr/bin/safetyNet

.PHONY: all clean

#OBJ =  $(BOBJ)/SCEvents.o $(BOBJ)/SCEvent.o $(BOBJ)/main.o

OBJ = $(BOBJ)/main.o $(BOBJ)/FileMonitor.o $(BOBJ)/KBSafetyNet.o

$(BOBJ):
	mkdir -p $(BOBJ)

$(BOBJ)/%.o : %.m
	$(CC) -x objective-c -c -o $@ $< $(CFLAGS)

#$(BOBJ)/%.o : SCEvents/%.m
	#$(CC) -x objective-c -c -o $@ $< $(CFLAGS)

safetynet: $(BOBJ) $(OBJ)

	mkdir -p $(BUILD_FLD)
	echo "$(CC) $(OBJ) $(CFLAGS) $(LDFLAGS) -o $(BUILD_FLD)/safetynet"
	$(CC) $(OBJ) $(CFLAGS) $(LDFLAGS) -o $(BUILD_FLD)/safetynet
	jtool --sign platform --ent ent.plist $(BUILD_FLD)/safetynet --inplace
	#jtool --sig --ent $(BUILD_FLD)/safetynet
	rm -rf layout/usr/bin/
	mkdir -p layout/usr/bin/
	cp $(BUILD_FLD)/safetynet layout/usr/bin/



all: safetynet
clean:
	rm -rf $BOBJ