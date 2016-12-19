#  **Shell trials**

In the beginning there was shell, and it's been helping us since then.

So, to take a step forward in that direction, I have added some basic snippets in shell to help the fellow man get accustomed to the terminal.

---

## Searching with **se**
It is quite an easy to use command for easy searching of file with extensions.

**Examples**

 - Searching in the current folder:

		> se -- java
	
    This'll list down all the possible files with *java* extension in the current directory.

 - Searching in another directory: 

		> se -- java ./mydir

   This'll list down all the possible files with *java* extension in the *mydir* directory.
   
 - Searching for a file with partial matching name:
	
		> se myClass java
   This'll list down all *java* files containing word *myClass* in them (with ignored case).
