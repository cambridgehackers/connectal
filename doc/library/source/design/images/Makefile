
all: images

%.png: %.pdf
	pdftoppm -singlefile -png $(*).pdf $(*)

images: \
    data_accel_logical0.png \
    data_accel_logical1.png \
    data_accel_logical2.png \
    data_accel_logical3.png \
    data_accel_logical4.png \
    MemreadEngine.png \
    msc0.png \
    msc1.png \
    msc2.png \
    platform.png \
    platforms.png
