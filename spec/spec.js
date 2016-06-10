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
QUnit.test('label_html', function (assert) {
    assert.equal(lib.label_html('#a/b', 'c.txt'), '<input size=\"9\" value=\"a/b/c.txt\"><span class=\"basename\">c.txt</span>');
});
QUnit.test('lines_to_data', function (assert) {
    assert.deepEqual(
            lib.lines_to_data(['a', 'a/b', 'a/b/c', '', '']), // Empty lines at end should be stripped.
            [
                {
                    "id": "#/b",
                    "parent": "#",
                    "text": "<input size=\"2\" value=\"/b\"><span class=\"basename\">b</span>"
                },
                {
                    "id": "#/b/c",
                    "parent": "#/b",
                    "text": "<input size=\"4\" value=\"/b/c\"><span class=\"basename\">c</span>"
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
                    "text": "<input size=\"2\" value=\"/b\"><span class=\"basename\">b</span> (txt)"
                },
                {
                    "id": "#/b/c.txt",
                    "parent": "#/b",
                    "text": "<input size=\"8\" value=\"/b/c.txt\"><span class=\"basename\">c.txt</span>"
                },
                {
                    "id": "#/b/d.xml",
                    "parent": "#/b",
                    "text": "<input size=\"8\" value=\"/b/d.xml\"><span class=\"basename\">d.xml</span>"
                },
                {
                    "id": "#/b/e.xml",
                    "parent": "#/b",
                    "text": "<input size=\"8\" value=\"/b/e.xml\"><span class=\"basename\">e.xml</span>"
                },
                {
                    "id": "#/z",
                    "parent": "#",
                    "text": "<input size=\"2\" value=\"/z\"><span class=\"basename\">z</span> (txt)"
                },
                {
                    "id": "#/z/z.txt",
                    "parent": "#/z",
                    "text": "<input size=\"8\" value=\"/z/z.txt\"><span class=\"basename\">z.txt</span>"
                }
            ]);
});
QUnit.test('descendant_counts', function (assert) {
    assert.deepEqual(
            lib.descendant_counts(lib.lines_to_data(['a', 'a/b', 'a/b/c.txt'])),
            {
                "#": 2,
                "#/b": 1
            });
});
QUnit.test('add_counts_to_data', function (assert) {
    assert.deepEqual(
            lib.add_counts_to_data(
                    lib.lines_to_data(['a', 'a/b', 'a/b/c.txt'])),
            [
                {
                    "id": "#/b",
                    "parent": "#",
                    "text": "<input size=\"2\" value=\"/b\"><span class=\"basename\">b</span><span class=\"count\">1</span>"
                },
                {
                    "id": "#/b/c.txt",
                    "parent": "#/b",
                    "text": "<input size=\"8\" value=\"/b/c.txt\"><span class=\"basename\">c.txt</span>"
                }
            ]);
});
