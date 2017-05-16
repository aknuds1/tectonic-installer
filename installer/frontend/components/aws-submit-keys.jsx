import _ from 'lodash';
import React from 'react';

import { validate } from '../validate';
import { Connect, Selector } from './ui';
import { Field, Form } from '../form';

import * as awsActions from '../aws-actions';
import { AWS_SSH } from '../cluster-config';

const awsSshForm = new Form('AWSSSHForm', [
  new Field(AWS_SSH, {
    default: '',
    validator: validate.nonEmpty,
    dependencies: ['AWSCreds'],
    getExtraStuff: (dispatch, isNow) => dispatch(awsActions.getSsh(null, null, isNow)).then(options => ({options})),
  })], {
    validator: (data, cc) => {
      const key = data[AWS_SSH];
      const options = _.get(cc, ['extra', AWS_SSH, 'options']);
      if (options && key && !_.some(options, o => o.value === key)) {
        return 'wrong';
      }
    },
  }
);

export const AWS_SubmitKeys = () => <div>
  <div className="row form-group">
    <div className="col-xs-12">
      Keys are used for encryption and connection. <a href="https://coreos.com/tectonic/docs/latest/install/aws/requirements.html#ssh-key" target="_blank">Generate new keys</a> if you don't have any existing ones.
    </div>
  </div>
  <div className="row form-group">
    <div className="col-xs-12">
      <h4>SSH Keys</h4>
      <Connect field={AWS_SSH}>
        <Selector refreshBtn={true} disabledValue="Please select SSH Key Pair" />
      </Connect>
      <awsSshForm.Errors />
    </div>
  </div>
</div>;

AWS_SubmitKeys.canNavigateForward = awsSshForm.canNavigateForward;
