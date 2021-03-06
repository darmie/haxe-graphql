package tests.operations;

import buddy.*;
using buddy.Should;

class ArgsQuery extends BuddySuite
{
  // TODO: directives:  content @include(if: $include_content) {

  public static inline var gql = '
query GetReturnOfTheJedi($$id: ID) {
  film(id: $$id) {
    title
    director
    releaseDate
  }
}';

  public function new() {
    describe("ArgsQuery: The Parser", {

      var parser:graphql.parser.Parser;

      it('should parse the ARGS query document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      it("should parse 1 definitions and 1 selection from this schema", {
        parser.document.definitions.length.should.be(1);

        var d:Dynamic = parser.document.definitions[0];
        d.selectionSet.selections.length.should.be(1);
      });

    });

    // Can't generate without full schema, see QueryTypeGeneration for full gen / compile
  }

}

