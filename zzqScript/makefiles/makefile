.PHONY:clean show

CFLAGS = -Iinclude

EXECUTABLE = $(BINDIR)/my_program
    
OBJ = 
TARGET = exe
$(TARGET):$(OBJ)
	$(CXX) $^ -o $@
%.o:%.cpp
	$(CXX) -c $^ -o $@
clean:
	$(RM) *.o $(TARGET)
