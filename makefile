PROJET= NOSEU
BIN_LIB=$(PROJET)BIN
DB_LIB=QIWS
DBGVIEW=*ALL
DBGVIEWSQL=*SOURCE
LIBLIST= $(DB_LIB) $(BIN_LIB)
INC_LIB= '/home/YV/include/'
CCSID=297

# The shell we use
SHELL=/QOpenSys/usr/bin/qsh

all: crtlib init livrerst.srvpgm

# rules
crtlib: $(BIN_LIB).lib
# TODO: dans init ajouter le chargement de la table 
init: 
livrerst.srvpgm : livrerst.inc livrerst.sqlrpgle
%.lib:
	-system -q "CRTLIB $*"
	@touch $@

%.inc: src/qrpgleref/%.rpgleinc
	system "CHGATR OBJ('$<') ATR(*CCSID) VALUE(1208)" 
	cp  '$<'  $(INC_LIB)
	@touch $@

%.pgm:
	$(eval modules := $(patsubst %,$(BIN_LIB)/%,$(basename $(filter %.rpgle %.sqlrpgle,$(notdir $^)))))
	system "CHGATR OBJ('$<') ATR(*CCSID) VALUE(1208)" 
	liblist -af $(LIBLIST);\
	system "CRTPGM PGM($(BIN_LIB)/$*) MODULE($(modules))"
	@touch $@

%.rpgle: src/qrpglesrc/%.rpgle
	system "CHGATR OBJ('$<') ATR(*CCSID) VALUE(1208)" 
	liblist -af $(LIBLIST);\
	system "CRTRPGMOD MODULE($(BIN_LIB)/$*) SRCSTMF('$<') DBGVIEW($(DBGVIEW)) TGTCCSID($(CCSID))"
	@touch $@

%.sqlrpgle: src/qrpglesrc/%.sqlrpgle
	system "CHGATR OBJ('$<') ATR(*CCSID) VALUE(1208)" 
	liblist -af $(LIBLIST);\
	system "CRTSQLRPGI OBJ($(BIN_LIB)/$*) SRCSTMF('$<') COMMIT(*NONE) OBJTYPE(*MODULE) RPGPPOPT(*LVL2) COMPILEOPT('TGTCCSID($(CCSID))') DBGVIEW($(DBGVIEWSQL))"
	@touch $@

%.srvpgm: src/qsrvsrc/%.bnd
	$(eval modules := $(patsubst %,$(BIN_LIB)/%,$(basename $(filter %.rpgle %.sqlrpgle,$(notdir $^)))))
	system "CHGATR OBJ('$<') ATR(*CCSID) VALUE(1208)" 
	liblist -af $(LIBLIST);\
	system "CRTSRVPGM SRVPGM($(BIN_LIB)/$*) MODULE($(modules)) OPTION(*DUPPROC) SRCSTMF('$<')"

	@touch $@
	system "DLTOBJ OBJ($(BIN_LIB)/*ALL) OBJTYPE(*MODULE)"

%.entry:
    # Basically do nothing..
	@touch $@


clean:
	rm -f *.pgm *.rpgle *.sqlrpgle *.cmd *.srvpgm *.dspf *.bnddir *.entry *.inc *.cmp

	
release:
	@echo " -- Creating release. --"
	@echo " -- Creating save file. --"
	system "CRTSAVF FILE($(BIN_LIB)/RELEASE)"
	system "SAVLIB LIB($(BIN_LIB)) DEV(*SAVF) SAVF($(BIN_LIB)/RELEASE) OMITOBJ((RELEASE *FILE))"
	-rm -r release
	-mkdir release
	system "CPYTOSTMF FROMMBR('/QSYS.lib/$(BIN_LIB).lib/RELEASE.FILE') TOSTMF('./release/release.savf') STMFOPT(*REPLACE) STMFCCSID(1252) CVTDTA(*NONE)"
	@echo " -- Cleaning up... --"
	system "DLTOBJ OBJ($(BIN_LIB)/RELEASE) OBJTYPE(*FILE)"
	@echo " -- Release created! --"
	@echo ""
	@echo "To install the release, run:"
	@echo "  > CRTLIB $(BIN_LIB)"
	@echo "  > CPYFRMSTMF FROMSTMF('./release/release.savf') TOMBR('/QSYS.lib/$(BIN_LIB).lib/RELEASE.FILE') MBROPT(*REPLACE) CVTDTA(*NONE)"
	@echo "  > RSTLIB SAVLIB($(BIN_LIB)) DEV(*SAVF) SAVF($(BIN_LIB)/RELEASE)"
	@echo ""
