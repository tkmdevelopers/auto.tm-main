'use strict';
/** No-op migration kept only to preserve original timestamp ordering after integrating replyTo directly in create-comments migration. */
module.exports = {
  async up() { /* intentionally empty */ },
  async down() { /* intentionally empty */ },
};
