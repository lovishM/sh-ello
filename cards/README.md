# **Learn using flash cards**

Most of us have trouble with those situations, when you just can't remember a word. In those dire situations, we run to our dictionary looking for their meaning. So, I though of creating some scripts to accomplish the same, and here we are.

Listed are some of the tools created in shell, specifically to let the user get a terminal experience.

---
## Flash cards using **simplearn**

It's a very basic sourcing script, which can just be included like so in your **.bashrc** file

    # Sourcing of simplearn (*assuming scipt is present in ${HOME}/simplearn.sh*)
    . ~/${HOME}/cards/simplearn/simplearn.sh

This sourcing would enable the commands **learn** and **add** to the environment.

To simply start learning run the following

    $ learn

To add new words execute

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

That's all folks, as easy as that. Hope you enjoy it.
