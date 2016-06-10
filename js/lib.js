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
    label_html: function(dir, base) {
        var path = dir.slice(1) + '/' + base;
        return $('<div>')
                .append($('<input>').attr('value',path).attr('size', path.length))
                .append($('<span class="basename">').text(base))
                .html();
    },
    lines_to_data: function (lines) {
        var prefix = lines[0];
        return $.map(
                $.grep(lines.slice(1), function (line) {
                    return line; // Ignore blank lines.
                }),
                function (line) {
                    var id = '#' + line.split(prefix).slice(1).join(prefix);
                    return {
                        id: id,
                        parent: lib.dirname(id),
                        text: lib.label_html(lib.dirname(id),lib.basename(id))
                    };
                });
    },
    descendant_extensions: function (data) {
        var index = {};
        $.each(data, function (i, datum) {
            var ancestors = lib.ancestors(datum.parent);
            var extension = lib.extension($(datum.text).text()); // .text is really html.
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
    add_extensions_to_data: function (data, only_show) {
        var extensions_index = lib.descendant_extensions(data);
        return $.map(data, function (datum) {
            var extensions = $.grep(
                    Object.keys(extensions_index[datum.id] || {}),
                    function (extension) {
                        return only_show.indexOf(extension) !== -1;
                    });
            datum.text = extensions.length > 0
                    ? datum.text + ' (' + extensions.join(' ') + ')'
                    : datum.text;
            return datum;
        });
    }
};
