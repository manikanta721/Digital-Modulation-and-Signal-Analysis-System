CXX ?= g++
CXXFLAGS ?= -std=c++17 -O2 -Wall -Wextra
SRC = main.cpp SignalGenerator.cpp Modulation.cpp Noise.cpp FFT.cpp Filter.cpp Demodulation.cpp Metrics.cpp Pipeline.cpp

dsp_app: $(SRC) *.h
	$(CXX) $(CXXFLAGS) -o $@ $(SRC)

test: dsp_app
	./dsp_app --test

clean:
	rm -f dsp_app *.csv
