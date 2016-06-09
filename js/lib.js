var lib = {
    dirname: function (path) {
        return path.split('/').slice(0, -1).join('/');
    },
    basename: function (path) {
        return path.split('/').slice(-1)[0];
    },
    extension: function (path) {
        var match = lib.basename(path).match(/\.([^.]+)$/);
        if (match) {
            return match[1];
        }
    },
    ancestors: function (path) {
        var ancestors = [];
        var current = lib.dirname(path);
        while (current !== "") {
            ancestors.push(current);
            current = lib.dirname(current);
        }
        return ancestors;
    },
    lines_to_data: function (lines) {
        var prefix = lines[0];
        return $.map(lines.slice(1), function (line) {
            var id = '#' + line.split(prefix).slice(1).join(prefix);
            return {
                id: id,
                parent: lib.dirname(id),
                text: lib.basename(id)
            };
        });
    }
};
