import buddy.*;
using buddy.Should;

class Main implements Buddy<[
                             tests.basic.BasicTypes,
                             tests.basic.ValidHaxe,
                             tests.basic.BasicSchema,
                             tests.args.ArgsDefaultValues,
                             tests.star_wars.StarWarsTest
]> {}
