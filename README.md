# Cstub

Simple C stub generator.

## Installation

Add this line to your application's Gemfile:

    gem 'cstub'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cstub

## Usage

    Usage: cstub [options]
        -I/your/include/path
        -DMACRO
        --cpp Preprocessor
        --filter filter.txt

example:

    $ ls
    my_dependency.h my_product_code.c my_product_code.o

    $ arm-none-eabi-nm -u my_product_code.o > filter.txt

    $ cat filter.txt
             U depend_function
             U depend_function2
             U depend_function3

    $ cstub *.c --filter filter.txt --cpp "arm-none-eabi-gcc -P -E"
    int depend_function(int par0)
    {
        return 0;
    }
    MY_INT depend_function2(volatile unsigned int a, int b, int c)
    {
        return 0;
    }
    ERROR_CODE depend_function3(int par0)
    {
        return ERROR_NONE;
    }

## Contributing

1. Fork it ( https://github.com/kunigaku/cstub/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
