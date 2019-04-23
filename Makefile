RACKET=racket
RACO=raco
MAIN=main.rkt
NIGHTLY=nightly.rkt

all:
	${RACO} make ${MAIN}
	PLTSTDERR="error info@gtp-checkup" ${RACO} test ${MAIN}

nightly:
	PLTSTDERR="error info@gtp-checkup" ${RACKET} ${NIGHTLY}
