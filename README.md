#  **Shell trials**

In the beginning there was shell, and it's been helping us since then.

So, to take a step forward in that direction, I have added some basic snippets in shell to help the fellow man get accustomed to the terminal.

---

## Searching with **se**
It is quite an easy to use command for easy searching of file with extensions.

**Examples**

 - Searching in the current folder:

    $ se -- java
	
    This'll list down all the possible files with *java* extension in the current directory.

 - Searching in another directory: 

    $ se -- java ./mydir

   This'll list down all the possible files with *java* extension in the *mydir* directory.
   
 - Searching for a file with partial matching name:
	
    $ se myClass java
    This'll list down all *java* files containing word *myClass* in them (with ignored case).


## Flash cards using **simplearn**

It's a very basic sourcing script, which can just be included like so in your **.bashrc** file

    # Sourcing of simplearn (*assuming scipt is present in ${HOME}/simplearn.sh*)
    . ~/${HOME}/cards/simplearn/simplearn.sh

This sourcing would enable the commands **learn** and **add** to the environment.

- To simply start learning run the following

    $ learn

- To add new words execute

    $ add

## Flash cards using **flash-em**

This is a terminal GUI enabled script, and therefore may not run on every system efficiently. But, its
way more attractive to work with (as you'd realize).

The following is the usage assuming script is kept in **${HOME}/flash-em.sh**

    $ ~/flash-em.sh

Or you could create an alias in **${HOME}/.bashrc**, like so

    # Alias for flash-em
    alias cards='${HOME}/flash-em.sh'

After this, a simple execute of **cards**, would run the same.
