import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:glob/glob.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' show ExitCode;
import 'package:logging/logging.dart';

import '../command_builder.dart';
import '../utils/ensure_process_exit.dart';
import '../utils/has_any_positional_args_before_separator.dart';
import '../utils/package_is_immediate_dependency.dart';
import '../utils/parse_flag_from_args.dart';
import '../utils/verbose_enabled.dart';

final _log = Logger('Format');

class FormatCommand implements CommandBuilder {
  FormatMode defaultMode = FormatMode.overwrite;

  @override
  String description;

  List<Glob> exclude = [];

  Formatter formatter = Formatter.dartfmt;

  @override
  bool hidden;

  List<Glob> include = [];

  int lineLength;

  @override
  Command<int> build(String commandName) => _FormatCommand(
        commandName,
        defaultMode,
        description,
        exclude,
        formatter,
        hidden,
        include,
        lineLength,
      );
}

class _FormatCommand extends Command<int> {
  final String _commandName;
  final FormatMode _defaultMode;
  final String _description;
  final List<Glob> _exclude;
  final Formatter _formatter;
  final bool _hidden;
  final List<Glob> _include;
  final int _lineLength;

  _FormatCommand(
    this._commandName,
    this._defaultMode,
    this._description,
    this._exclude,
    this._formatter,
    this._hidden,
    this._include,
    this._lineLength,
  );

  @override
  String get name => _commandName ?? 'format';

  @override
  String get description =>
      _description ?? 'Format dart files in this package.';

  @override
  bool get hidden => _hidden ?? false;

  @override
  String get invocation =>
      '${super.invocation.replaceFirst('[arguments]', '[dart_dev arguments]')} '
      '[-- [formatter arguments]]';

  @override
  String get usageFooter => '\n'
      'Run "${_fmtExecutable} -h" to see the available formatter arguments.\n'
      'You can use any of them with "dart_dev $name" by passing them after a '
      '"--" separator.';

  String get _fmtExecutable => _formatter == Formatter.dartStyle
      ? 'pub run dart_style:format'
      : 'dartfmt';

  @override
  Future<int> run() async {
    if (hasAnyPositionalArgsBeforeSeparator(argResults)) {
      usageException('This "$name" command does not support positional args '
          'before the `--` separator.\n'
          'Args for the dart formatter should be passed in after a `--` '
          'separator.');
    }

    final dryRun = parseFlagFromArgs(argResults.rest, 'dry-run', abbr: 'n');
    final overwrite =
        parseFlagFromArgs(argResults.rest, 'overwrite', abbr: 'w');
    final noModeSelected = !dryRun && !overwrite;

    String executable;
    List<String> executableArgs;
    switch (_formatter) {
      case Formatter.dartStyle:
        if (!packageIsImmediateDependency('dart_style')) {
          _log.severe(red.wrap('Cannot run `dart_style:format`.\n') +
              yellow.wrap('You must either have a dependency on `dart_style` '
                  'in `pubspec.yaml` or configure the format tool to use `dartfmt`'
                  'instead.\n'
                  'Either add "dart_style" to your pubspec.yaml or configure the '
                  'format tool to use "dartfmt" instead.'));
          return ExitCode.config.code;
        }
        executable = 'pub';
        executableArgs = ['run', 'dart_style:format'];
        break;

      case Formatter.dartfmt:
      default:
        executable = 'dartfmt';
        executableArgs = [];
    }

    // Build the list of inputs (includes minus excludes).
    final excludeGlobs = _exclude ?? [];
    final includeGlobs =
        _include ?? [excludeGlobs.isEmpty ? Glob('.') : Glob('**.dart')];
    final include = {
      for (final glob in includeGlobs)
        ...glob
            .listSync()
            .where((entity) => entity is File || entity is Directory)
            .map((file) => file.path),
      // .where((path) => !exclude.any((glob) => glob.matches(path))),
    };
    final exclude = {
      for (final glob in excludeGlobs)
        ...glob
            .listSync()
            .where((entity) => entity is File || entity is Directory)
            .map((file) => file.path),
    };
    final inputs = include.difference(exclude);
    if (inputs.isEmpty) {
      inputs.add('.');
    }

    _log.fine('Excluding these paths from formatting:\n\t'
        '${include.intersection(exclude).join('\n\t')}');

    final args = [
      ...executableArgs,

      // Pass in a default mode if one was not selected.
      if (noModeSelected && _defaultMode == FormatMode.dryRun)
        '-n',
      if (noModeSelected && _defaultMode == FormatMode.overwrite)
        '-w',

      // Pass in the line-length if configured.
      if (_lineLength != null) ...['-l', '$_lineLength'],

      // Pass through the rest of the args (this may be empty).
      ...argResults.rest,
    ];

    if (inputs.length <= 5 || verboseEnabled(this)) {
      _log.info(
          'Running: ${executable} ${args.join(' ')} ${inputs.join(' ')}\n');
    } else {
      _log.info(
          'Running: ${executable} ${args.join(' ')} <${inputs.length} paths>\n');
    }

    final process = await Process.start(
      executable,
      [...args, ...inputs],
      mode: ProcessStartMode.inheritStdio,
    );
    ensureProcessExit(process, log: _log);
    return process.exitCode;
  }
}

// class FormatConfig {
//   FormatConfig({
//     this.commandName,
//     this.defaultMode,
//     this.exclude,
//     this.formatter,
//     this.hidden,
//     this.include,
//     this.lineLength,
//   });

//   final String commandName;

//   final FormatMode defaultMode;

//   final List<Glob> exclude;

//   final Formatter formatter;
//   final List<Glob> include;

//   final int lineLength;
//   final bool hidden;

//   FormatConfig merge(FormatConfig other) => FormatConfig(
//         commandName: other?.commandName ?? commandName,
//         defaultMode: other?.defaultMode ?? defaultMode,
//         exclude: other?.exclude ?? exclude,
//         formatter: other?.formatter ?? formatter,
//         hidden: other?.hidden ?? hidden,
//         include: other?.include ?? include,
//         lineLength: other?.lineLength ?? lineLength,
//       );
// }

enum FormatMode {
  dryRun,
  overwrite,
  printChanges,
}

enum Formatter {
  dartfmt,
  dartStyle,
}
