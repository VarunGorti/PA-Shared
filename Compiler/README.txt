---------------------------------------HOW TO COMPILE PROGRAMS----------------------------------------------------------------
In command line, go to the directory containing FunCompiler.jar

Then do "java -jar FunCompiler.jar [Name of File to Compile] [*Optional Stack Size (default is 500)]

For instance, java -jar FunCompiler.jar fourcoreaddition.txt

The File to Compile must be a .txt file and the produced file will be .hex file

Everything was compiled with the default stack size of 500, so stack size argument should not be needed

Alternatively you can open the included FunCompiler directory in IntelliJ or something similar and run FunCompilerRunner.java

When running the .jar, ensure standardlib.txt is in the same directory



---------------------------------------LANGUAGE SYNTAX AND RULES---------------------------------------------------------------
Most of the rules are the same as p4 fun, some differences are
- No multiplication, but addition (+) and subtraction (-) and == (equality returns 1 if equal 0 otherwise)
- Functions may have arguments (e.g. sum = fun(x,y){...}). Currently we only support up to 3 parameters.
	-Arguments are pass by value
	-Expressions can be arguments, such as sum(x + (1 == 1), y - z)
- Functions may return values   (e.g. return x + y)
- Some predefined functions that may be useful
	- printnum(x), prints x as a number rather than ascii
	- wake(core, pc), specified core starts running at specified pc. (cores are indexed 0,1,2,3). pc is almost always going to be a function. (E.g. wake(2,sum) will cause core 2's pc to go to sum)
	- pause(core), pauses core
	- resume(core), resumes core
	- Although they are called pause and resume, the order does not matter so pause(core X) then resume(core X) as same effect as resume(core X) then pause(core X)
-$ in front of hex string (0-9, lower case letters), will add that hex string to the program at that spot. (Similar idea to in-line assembly in C)
- Variables still need to be all lower case + numbers

---------------------------------------Test Case Descriptions-----------------------------------------------------------------
fourcoreaddition.txt - Uses four cores to add up numbers 1-100 faster
functionasarg.txt    - Able to pass function address as argument
multiprint.txt       - Basic program showing how the cores run
pauseresume.txt      - Example of how pause/resume work
sumrecursivedepth.txt- Shows recursion is supported by our stack

