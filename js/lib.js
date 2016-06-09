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
        // Actually, ancestors + self
        var ancestors = [];
        var current = path;
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
    },
    descendant_extensions: function (data) {
        var index = {};
        $.each(data, function (i, datum) {
            var ancestors = lib.ancestors(datum.parent);
            var extension = lib.extension(datum.text);
            if (extension) {
                $.each(ancestors, function (i, ancestor) {
                    if (!index[ancestor]) {
                        index[ancestor] = {};
                    }
                    index[ancestor][extension] = true;
                });
            }
        });
        return index;
    },
    add_extensions_to_data: function (data) {
        var extensions = lib.descendant_extensions(data);
        return $.map(data, function (datum) {
            datum.text = extensions[datum.id]
                    ? datum.text + ' (' + Object.keys(extensions[datum.id]).join(' ') + ')'
                    : datum.text;
            return datum;
        });
    }
};
