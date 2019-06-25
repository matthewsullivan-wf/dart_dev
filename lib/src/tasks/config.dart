// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library dart_dev.src.tasks.config;

import 'package:dart_dev/src/tasks/analyze/config.dart';
import 'package:dart_dev/src/tasks/bash_completion/config.dart';
import 'package:dart_dev/src/tasks/copy_license/config.dart';
import 'package:dart_dev/src/tasks/coverage/config.dart';
import 'package:dart_dev/src/tasks/dart_x_only/config.dart';
import 'package:dart_dev/src/tasks/format/config.dart';
import 'package:dart_dev/src/tasks/gen_test_runner/config.dart';
import 'package:dart_dev/src/tasks/init/config.dart';
import 'package:dart_dev/src/tasks/sass/config.dart';
import 'package:dart_dev/src/tasks/task_runner/config.dart';
import 'package:dart_dev/src/tasks/test/config.dart';
import 'package:dart_dev/src/tasks/local/config.dart';

Config config = new Config();

class Config {
  AnalyzeConfig analyze = new AnalyzeConfig();
  BashCompletionConfig bashCompletion = new BashCompletionConfig();
  CopyLicenseConfig copyLicense = new CopyLicenseConfig();
  CoverageConfig coverage = new CoverageConfig();
  Dart1OnlyConfig dart1Only = new Dart1OnlyConfig();
  Dart2OnlyConfig dart2Only = new Dart2OnlyConfig();
  LocalConfig local = new LocalConfig();
  FormatConfig format = new FormatConfig();
  GenTestRunnerConfig genTestRunner = new GenTestRunnerConfig();
  InitConfig init = new InitConfig();
  TaskRunnerConfig taskRunner = new TaskRunnerConfig();
  TestConfig test = new TestConfig();
  SassConfig sass = new SassConfig();

  Map<String, dynamic> toJson() => {
        'analyze': analyze,
        'bashCompletion': bashCompletion,
        'copyLicense': copyLicense,
        'coverage': coverage,
        'local': local,
        'format': format,
        'genTestRunner': genTestRunner,
        'init': init,
        'taskRunner': taskRunner,
        'test': test,
        'sass': sass,
      };
}

class TaskConfig {
  List after = [];
  List before = [];
}
