/* Copyright JS Foundation and other contributors, http://js.foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "jerryscript.h"
#include "jerryscript-port.h"
#include "jerryscript-port-default.h"
#include "test-common.h"


const char *test_source = (
                           "var p1 = create_promise1();"
                           "var p2 = create_promise2();"
                           "p1.then(function(x) { "
                           "  assert(x==='resolved'); "
                           "}); "
                           "p2.catch(function(x) { "
                           "  assert(x==='rejected'); "
                           "}); "
                           );

static int count_in_assert = 0;
static jerry_value_t my_promise1;
static jerry_value_t my_promise2;
const jerry_char_t s1[] = "resolved";
const jerry_char_t s2[] = "rejected";

static jerry_value_t
create_promise1_handler (const jerry_value_t func_obj_val, /**< function object */
                         const jerry_value_t this_val, /**< this value */
                         const jerry_value_t args_p[], /**< arguments list */
                         const jerry_length_t args_cnt) /**< arguments length */
{
  JERRY_UNUSED (func_obj_val);
  JERRY_UNUSED (this_val);
  JERRY_UNUSED (args_p);
  JERRY_UNUSED (args_cnt);

  jerry_value_t ret =  jerry_create_promise ();
  my_promise1 = jerry_acquire_value (ret);

  return ret;
} /* create_promise1_handler */

static jerry_value_t
create_promise2_handler (const jerry_value_t func_obj_val, /**< function object */
                         const jerry_value_t this_val, /**< this value */
                         const jerry_value_t args_p[], /**< arguments list */
                         const jerry_length_t args_cnt) /**< arguments length */
{
  JERRY_UNUSED (func_obj_val);
  JERRY_UNUSED (this_val);
  JERRY_UNUSED (args_p);
  JERRY_UNUSED (args_cnt);

  jerry_value_t ret =  jerry_create_promise ();
  my_promise2 = jerry_acquire_value (ret);

  return ret;
} /* create_promise2_handler */

static jerry_value_t
assert_handler (const jerry_value_t func_obj_val, /**< function object */
                const jerry_value_t this_val, /**< this arg */
                const jerry_value_t args_p[], /**< function arguments */
                const jerry_length_t args_cnt) /**< number of function arguments */
{
  JERRY_UNUSED (func_obj_val);
  JERRY_UNUSED (this_val);

  count_in_assert++;

  if (args_cnt == 1
      && jerry_value_is_boolean (args_p[0])
      && jerry_get_boolean_value (args_p[0]))
  {
    return jerry_create_boolean (true);
  }
  else
  {
    TEST_ASSERT (false);
  }
} /* assert_handler */

/**
 * Register a JavaScript function in the global object.
 */
static void
register_js_function (const char *name_p, /**< name of the function */
                      jerry_external_handler_t handler_p) /**< function callback */
{
  jerry_value_t global_obj_val = jerry_get_global_object ();

  jerry_value_t function_val = jerry_create_external_function (handler_p);
  jerry_value_t function_name_val = jerry_create_string ((const jerry_char_t *) name_p);
  jerry_value_t result_val = jerry_set_property (global_obj_val, function_name_val, function_val);

  jerry_release_value (function_name_val);
  jerry_release_value (function_val);
  jerry_release_value (global_obj_val);

  jerry_release_value (result_val);
} /* register_js_function */

/**
 * Checks whether global object has promise.
 */
static bool
promise_is_available (void)
{
  jerry_value_t global_obj_val = jerry_get_global_object ();
  jerry_value_t prop_name = jerry_create_string ((const jerry_char_t *) "Promise");

  jerry_value_t prop_value = jerry_has_property (global_obj_val, prop_name);
  bool has_prop = jerry_get_boolean_value (prop_value);

  jerry_release_value (global_obj_val);
  jerry_release_value (prop_name);
  jerry_release_value (prop_value);

  return has_prop;
} /* promise_is_available */

int
main (void)
{
  jerry_init (JERRY_INIT_EMPTY);

  if (!promise_is_available ())
  {
    jerry_port_log (JERRY_LOG_LEVEL_ERROR, "Promise is disabled!\n");
    jerry_cleanup ();
    return 0;
  }

  register_js_function ("create_promise1", create_promise1_handler);
  register_js_function ("create_promise2", create_promise2_handler);
  register_js_function ("assert", assert_handler);

  jerry_value_t parsed_code_val = jerry_parse ((jerry_char_t *) test_source, strlen (test_source), false);
  TEST_ASSERT (!jerry_value_has_error_flag (parsed_code_val));

  jerry_value_t res = jerry_run (parsed_code_val);
  TEST_ASSERT (!jerry_value_has_error_flag (res));

  jerry_release_value (res);
  jerry_release_value (parsed_code_val);

  /* Test jerry_create_promise and jerry_value_is_promise. */
  TEST_ASSERT (jerry_value_is_promise (my_promise1));
  TEST_ASSERT (jerry_value_is_promise (my_promise2));

  TEST_ASSERT (count_in_assert == 0);

  /* Test jerry_resolve_or_reject_promise. */
  jerry_value_t str_resolve = jerry_create_string (s1);
  jerry_value_t str_reject = jerry_create_string (s2);

  jerry_resolve_or_reject_promise (my_promise1, str_resolve, true);
  jerry_resolve_or_reject_promise (my_promise2, str_reject, false);

  /* The resolve/reject function should be invalid after the promise has the result. */
  jerry_resolve_or_reject_promise (my_promise2, str_resolve, true);
  jerry_resolve_or_reject_promise (my_promise1, str_reject, false);

  /* Run the jobqueue. */
  res = jerry_run_all_enqueued_jobs ();

  TEST_ASSERT (!jerry_value_has_error_flag (res));
  TEST_ASSERT (count_in_assert == 2);

  jerry_release_value (my_promise1);
  jerry_release_value (my_promise2);
  jerry_release_value (str_resolve);
  jerry_release_value (str_reject);

  jerry_cleanup ();
} /* main */
