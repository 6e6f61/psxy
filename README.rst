psxy
====

A very well documented PlayStation 1 emulator.

Documentation
-------------

Some of psxy's documentation can be read from autodoc:

.. code-block::

    $ zig build-exe -fno-emit-bin -femit-docs
    $ xdg-open docs/index.html

And then checking "Internal Doc Mode".

This documentation is generated from comments in the source code, though not all comments are
present - reading the source code will be a better resource.

Tests
-----

Some tests require an assortment of BIOS images to be available in the bios/ directory. Expect some
tests to fail if these aren't supplied.