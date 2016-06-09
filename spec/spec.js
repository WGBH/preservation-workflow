// Just to silence warnings:
var QUnit = (QUnit === undefined) ? {} : QUnit;
var lib = (lib === undefined) ? {} : lib;

QUnit.test('dirname', function (assert) {
    assert.equal(lib.dirname('a/b/c'), 'a/b');
});
QUnit.test('basename', function (assert) {
    assert.equal(lib.basename('a/b/c'), 'c');
});
QUnit.test('extension, set', function (assert) {
    assert.equal(lib.extension('a/b/c.foo.bar'), 'bar');
});
QUnit.test('extension, unset', function (assert) {
    assert.equal(lib.extension('a/b/c'), null);
});
QUnit.test('ancestors, deep', function (assert) {
    assert.deepEqual(lib.ancestors('a/b/c'), ['a/b/c', 'a/b', 'a']);
});
QUnit.test('ancestors, shallow', function (assert) {
    assert.deepEqual(lib.ancestors('a'), ['a']);
});
QUnit.test('lines_to_data', function (assert) {
    assert.deepEqual(
            lib.lines_to_data(['a', 'a/b', 'a/b/c', '', '']), // Empty lines at end should be stripped.
            [
                {
                    "id": "#/b",
                    "parent": "#",
                    "text": "b"
                },
                {
                    "id": "#/b/c",
                    "parent": "#/b",
                    "text": "c"
                }
            ]);
});
QUnit.test('descendant_extensions', function (assert) {
    assert.deepEqual(
            lib.descendant_extensions(lib.lines_to_data(['a', 'a/b', 'a/b/c.txt'])),
            {
                "#": {
                    "txt": true
                },
                "#/b": {
                    "txt": true
                }
            });
});
QUnit.test('add_extensions_to_data', function (assert) {
    assert.deepEqual(
            lib.add_extensions_to_data(
                lib.lines_to_data(['a', 'a/b', 'a/b/c.txt', 'a/b/d.xml', 'a/b/e.xml', 'a/z', 'a/z/z.txt']),
                ['txt']),
            [
                {
                    "id": "#/b",
                    "parent": "#",
                    "text": "b (txt)"
                },
                {
                    "id": "#/b/c.txt",
                    "parent": "#/b",
                    "text": "c.txt"
                },
                {
                    "id": "#/b/d.xml",
                    "parent": "#/b",
                    "text": "d.xml"
                },
                {
                    "id": "#/b/e.xml",
                    "parent": "#/b",
                    "text": "e.xml"
                },
                {
                    "id": "#/z",
                    "parent": "#",
                    "text": "z (txt)"
                },
                {
                    "id": "#/z/z.txt",
                    "parent": "#/z",
                    "text": "z.txt"
                }
            ]);
});
