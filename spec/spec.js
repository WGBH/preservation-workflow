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
    assert.deepEqual(lib.ancestors('a/b/c'), ['a/b', 'a']);
});
QUnit.test('ancestors, shallow', function (assert) {
    assert.deepEqual(lib.ancestors('a'), []);
});
QUnit.test('lines_to_data', function (assert) {
    assert.deepEqual(
            lib.lines_to_data(['a', 'a/b', 'a/b/c']),
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

